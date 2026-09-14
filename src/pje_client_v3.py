from __future__ import annotations

import asyncio
import io
import re
import time
from typing import Any

import pdfplumber
from playwright.async_api import Browser, BrowserContext, Page, async_playwright

from config import MANUAL_TOTP_TIMEOUT, PROFILE_HINT, URL_BASES, normalize_grau


class PJeAdapterError(RuntimeError):
    pass


class PJeClientV3:
    """Cliente somente leitura com autenticação realizada manualmente no navegador."""

    def __init__(self, grau: str = "2g", headless: bool = False):
        self.grau = normalize_grau(grau)
        self.base_url = URL_BASES[self.grau]
        self.headless = headless
        self._pw = None
        self._browser: Browser | None = None
        self._context: BrowserContext | None = None
        self._page: Page | None = None
        self._op_lock = asyncio.Lock()

    def is_alive(self) -> bool:
        return bool(self._browser and self._browser.is_connected())

    @property
    def page(self) -> Page:
        if not self._page:
            raise PJeAdapterError("Sessão PJe não iniciada")
        return self._page

    async def start(self) -> None:
        if self.headless:
            raise PJeAdapterError("Use PJE_HEADLESS=0 para concluir o acesso manualmente no navegador.")
        self._pw = await async_playwright().start()
        self._browser = await self._pw.chromium.launch(headless=False)
        self._context = await self._browser.new_context(viewport={"width": 1440, "height": 900})
        self._page = await self._context.new_page()
        await self._page.goto(f"{self.base_url}/login.seam", wait_until="domcontentloaded", timeout=45000)
        await self._aguardar_acesso_manual()
        if PROFILE_HINT:
            await self.select_profile(PROFILE_HINT)

    async def _aguardar_acesso_manual(self) -> None:
        deadline = time.monotonic() + MANUAL_TOTP_TIMEOUT
        while time.monotonic() < deadline:
            await self.page.wait_for_timeout(1000)
            url = self.page.url.lower()
            if "pje.tjce.jus.br" in url and not any(x in url for x in ("login", "auth", "sso")):
                return
        raise PJeAdapterError("Tempo esgotado aguardando a conclusão manual do acesso ao PJe-TJCE.")

    async def close(self) -> None:
        if self._browser:
            await self._browser.close()
        if self._pw:
            await self._pw.stop()
        self._browser = self._context = self._page = self._pw = None

    async def select_profile(self, hint: str) -> dict[str, Any]:
        candidates = self.page.get_by_text(re.compile(re.escape(hint), re.I))
        if await candidates.count():
            await candidates.first.click(timeout=5000)
            await self.page.wait_for_timeout(800)
            return {"ok": True, "perfil": hint}
        return {"ok": False, "perfil": hint, "motivo": "perfil não localizado automaticamente"}

    async def health(self) -> dict[str, Any]:
        return {
            "ok": self.is_alive(),
            "grau": self.grau,
            "url": self.page.url,
            "somente_leitura": True,
            "autenticacao": "manual_no_navegador",
        }

    async def _open_search(self) -> None:
        for url in (
            f"{self.base_url}/Processo/ConsultaProcesso/listView.seam",
            f"{self.base_url}/ConsultaPublica/listView.seam",
        ):
            try:
                await self.page.goto(url, wait_until="domcontentloaded", timeout=20000)
                if "login" not in self.page.url.lower():
                    return
            except Exception:
                continue
        raise PJeAdapterError("Não foi possível abrir a consulta do PJe-TJCE")

    async def consultar_processo(self, numero_cnj: str) -> dict[str, Any]:
        numero = re.sub(r"\D", "", numero_cnj)
        if len(numero) != 20:
            raise ValueError("Número CNJ deve conter 20 dígitos")
        async with self._op_lock:
            await self._open_search()
            field = None
            for selector in (
                "input[id*='numeroProcesso']",
                "input[name*='numeroProcesso']",
                "input[placeholder*='processo' i]",
            ):
                loc = self.page.locator(selector)
                if await loc.count():
                    field = loc.first
                    break
            if field is None:
                raise PJeAdapterError("Campo de número do processo não localizado nesta versão do PJe-TJCE")
            await field.fill(numero)
            buttons = self.page.get_by_role("button", name=re.compile("pesquisar|consultar|buscar", re.I))
            if await buttons.count():
                await buttons.first.click()
            else:
                await field.press("Enter")
            await self.page.wait_for_timeout(1200)
            text = await self.page.locator("body").inner_text()
            return {"numero": numero_cnj, "grau": self.grau, "url": self.page.url, "texto_pagina": text[:20000]}

    async def ultimas_movimentacoes(self, numero_cnj: str, limite: int = 10) -> dict[str, Any]:
        result = await self.consultar_processo(numero_cnj)
        lines = [ln.strip() for ln in result["texto_pagina"].splitlines() if ln.strip()]
        date_re = re.compile(r"\b\d{2}/\d{2}/\d{4}\b")
        result["movimentacoes_candidatas"] = [ln for ln in lines if date_re.search(ln)][-max(1, min(limite, 100)):]
        return result

    async def listar_documentos(self, numero_cnj: str) -> dict[str, Any]:
        result = await self.consultar_processo(numero_cnj)
        links = await self.page.locator("a").evaluate_all(
            "els => els.map((e,i)=>({i,text:(e.innerText||'').trim(),href:e.href||''}))"
        )
        docs = [x for x in links if re.search(r"document|pdf|autos|visualiz|decis|senten|ac[oó]rd|parecer|manifest", (x.get("text", "") + " " + x.get("href", "")), re.I)]
        return {"numero": numero_cnj, "grau": self.grau, "documentos_candidatos": docs[:500], "url": result["url"]}

    async def preparar_processo_para_analise(self, numero_cnj: str) -> dict[str, Any]:
        consulta = await self.consultar_processo(numero_cnj)
        movimentacoes = await self.ultimas_movimentacoes(numero_cnj, 30)
        documentos = await self.listar_documentos(numero_cnj)
        categorias = {
            "decisao": r"decis|liminar|interlocut",
            "sentenca": r"senten",
            "acordao": r"ac[oó]rd",
            "recurso": r"apela|agravo|recurso",
            "contrarrazoes": r"contrarraz|contrarra",
            "manifestacao_mp": r"parecer|manifest.*minist|minist[eé]rio p[uú]blico|promotor|procurador",
        }
        classificados = []
        for doc in documentos.get("documentos_candidatos", []):
            texto = f"{doc.get('text', '')} {doc.get('href', '')}"
            categoria = "outro"
            for nome, pattern in categorias.items():
                if re.search(pattern, texto, re.I):
                    categoria = nome
                    break
            classificados.append({**doc, "categoria": categoria})
        return {
            "numero": numero_cnj,
            "grau": self.grau,
            "url": consulta.get("url"),
            "movimentacoes": movimentacoes.get("movimentacoes_candidatas", []),
            "documentos": classificados,
            "resumo_pagina": consulta.get("texto_pagina", "")[:8000],
            "somente_leitura": True,
        }

    async def ler_url_documento(self, url: str) -> dict[str, Any]:
        if not url.startswith("https://pje.tjce.jus.br/"):
            raise ValueError("URL de documento fora do domínio autorizado do PJe-TJCE")
        async with self._op_lock:
            response = await self.page.request.get(url, timeout=45000)
            if not response.ok:
                raise PJeAdapterError(f"Falha ao ler documento: HTTP {response.status}")
            body = await response.body()
            content_type = (response.headers.get("content-type") or "").lower()
            if "pdf" in content_type or body[:4] == b"%PDF":
                with pdfplumber.open(io.BytesIO(body)) as pdf:
                    text = "\n".join((p.extract_text() or "") for p in pdf.pages)
                return {"tipo": "pdf", "texto": text[:100000], "bytes": len(body)}
            text = body.decode("utf-8", errors="replace")
            text = re.sub(r"(?is)<script.*?</script>|<style.*?</style>", " ", text)
            text = re.sub(r"<[^>]+>", " ", text)
            text = re.sub(r"\s+", " ", text).strip()
            return {"tipo": "html", "texto": text[:100000], "bytes": len(body)}
