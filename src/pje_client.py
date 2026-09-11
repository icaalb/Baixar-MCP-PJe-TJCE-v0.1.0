from __future__ import annotations

import asyncio
import io
import re
import time
from dataclasses import dataclass
from typing import Any

import pdfplumber
import pyotp
from playwright.async_api import Browser, BrowserContext, Page, async_playwright

from config import PROFILE_HINT, URL_BASES, normalize_grau


class PJeAdapterError(RuntimeError):
    pass


@dataclass
class Credentials:
    cpf: str
    senha: str
    totp_seed: str


class PJeClient:
    """Adaptador somente-leitura para o PJe-TJCE.

    A v0.1.0 usa seletores resilientes e heurísticas. Qualquer operação que
    altere o processo (peticionar, assinar, dar ciência, responder expediente)
    fica deliberadamente fora do escopo.
    """

    def __init__(self, credentials: Credentials, grau: str = "2g", headless: bool = True):
        self.credentials = credentials
        self.grau = normalize_grau(grau)
        self.base_url = URL_BASES[self.grau]
        self.headless = headless
        self._pw = None
        self._browser: Browser | None = None
        self._context: BrowserContext | None = None
        self._page: Page | None = None
        self._op_lock = asyncio.Lock()

    async def start(self) -> None:
        self._pw = await async_playwright().start()
        self._browser = await self._pw.chromium.launch(headless=self.headless)
        self._context = await self._browser.new_context(viewport={"width": 1440, "height": 900})
        self._page = await self._context.new_page()
        await self.login()
        if PROFILE_HINT:
            await self.select_profile(PROFILE_HINT)

    async def close(self) -> None:
        if self._browser:
            await self._browser.close()
        if self._pw:
            await self._pw.stop()
        self._browser = self._context = self._page = self._pw = None

    @property
    def page(self) -> Page:
        if not self._page:
            raise PJeAdapterError("Sessão PJe não iniciada")
        return self._page

    async def _totp(self) -> str:
        totp = pyotp.TOTP(self.credentials.totp_seed)
        remaining = totp.interval - (int(time.time()) % totp.interval)
        if remaining < 3:
            await asyncio.sleep(remaining + 1)
        return totp.now()

    async def login(self) -> None:
        page = self.page
        await page.goto(f"{self.base_url}/login.seam", wait_until="domcontentloaded", timeout=45000)

        username = page.locator("input#username, input[name='username']")
        try:
            await username.first.wait_for(state="visible", timeout=7000)
        except Exception:
            if "pje.tjce.jus.br" in page.url:
                return
            raise PJeAdapterError(f"Tela de login não reconhecida: {page.url}")

        await username.first.fill(self.credentials.cpf)
        password = page.locator("input#password, input[name='password']")
        await password.first.fill(self.credentials.senha)
        submit = page.locator("#kc-login, button[type='submit'], input[type='submit']")
        await submit.first.click(timeout=5000)
        await page.wait_for_load_state("domcontentloaded", timeout=30000)

        otp = page.locator(
            "input[name='otp'], input[name='totp'], input#otp, input#totp, "
            "input[autocomplete='one-time-code']"
        )
        try:
            await otp.first.wait_for(state="visible", timeout=5000)
            await otp.first.fill(await self._totp())
            await page.locator("#kc-login, button[type='submit'], input[type='submit']").first.click(timeout=5000)
            await page.wait_for_load_state("domcontentloaded", timeout=30000)
        except Exception:
            pass

        await page.wait_for_timeout(1000)
        if "pje.tjce.jus.br" not in page.url:
            raise PJeAdapterError(f"Login não concluiu no PJe-TJCE. URL atual: {page.url}")

    async def select_profile(self, hint: str) -> dict[str, Any]:
        """Tenta selecionar um perfil institucional pelo texto, sem escrever no PJe."""
        async with self._op_lock:
            page = self.page
            candidates = page.get_by_text(re.compile(re.escape(hint), re.I))
            count = await candidates.count()
            if count:
                await candidates.first.click(timeout=5000)
                await page.wait_for_timeout(800)
                return {"ok": True, "perfil": hint}
            return {"ok": False, "perfil": hint, "motivo": "perfil não localizado automaticamente"}

    async def health(self) -> dict[str, Any]:
        async with self._op_lock:
            return {
                "ok": self._browser is not None and self._browser.is_connected(),
                "grau": self.grau,
                "url": self.page.url,
                "somente_leitura": True,
            }

    async def _open_search(self) -> None:
        page = self.page
        candidates = [
            f"{self.base_url}/Processo/ConsultaProcesso/listView.seam",
            f"{self.base_url}/ConsultaPublica/listView.seam",
        ]
        for url in candidates:
            try:
                await page.goto(url, wait_until="domcontentloaded", timeout=20000)
                if "login" not in page.url.lower():
                    return
            except Exception:
                continue
        raise PJeAdapterError("Não foi possível abrir a tela de consulta do PJe-TJCE")

    async def consultar_processo(self, numero_cnj: str) -> dict[str, Any]:
        numero = re.sub(r"\D", "", numero_cnj)
        if len(numero) != 20:
            raise ValueError("Número CNJ deve conter 20 dígitos")
        async with self._op_lock:
            await self._open_search()
            page = self.page
            selectors = [
                "input[id*='numeroProcesso']",
                "input[name*='numeroProcesso']",
                "input[placeholder*='processo' i]",
            ]
            field = None
            for sel in selectors:
                loc = page.locator(sel)
                if await loc.count():
                    field = loc.first
                    break
            if field is None:
                raise PJeAdapterError("Campo de número do processo não localizado; é necessário ajustar o adaptador TJCE")
            await field.fill(numero)
            buttons = page.get_by_role("button", name=re.compile("pesquisar|consultar|buscar", re.I))
            if await buttons.count():
                await buttons.first.click()
            else:
                await field.press("Enter")
            await page.wait_for_timeout(1200)
            text = await page.locator("body").inner_text()
            return {
                "numero": numero_cnj,
                "grau": self.grau,
                "url": page.url,
                "texto_pagina": text[:30000],
                "aviso": "retorno bruto inicial; parser específico do TJCE será refinado após teste autenticado",
            }

    async def ultimas_movimentacoes(self, numero_cnj: str, limite: int = 10) -> dict[str, Any]:
        result = await self.consultar_processo(numero_cnj)
        lines = [ln.strip() for ln in result["texto_pagina"].splitlines() if ln.strip()]
        date_re = re.compile(r"\b\d{2}/\d{2}/\d{4}\b")
        movs = [ln for ln in lines if date_re.search(ln)]
        result["movimentacoes_candidatas"] = movs[-max(1, min(limite, 100)):]
        return result

    async def listar_documentos(self, numero_cnj: str) -> dict[str, Any]:
        result = await self.consultar_processo(numero_cnj)
        page = self.page
        links = await page.locator("a").evaluate_all(
            "els => els.map((e,i)=>({i,text:(e.innerText||'').trim(),href:e.href||''}))"
        )
        docs = [x for x in links if re.search(r"document|pdf|autos|visualiz", (x.get("text","")+" "+x.get("href", "")), re.I)]
        return {"numero": numero_cnj, "grau": self.grau, "documentos_candidatos": docs[:500], "url": result["url"]}

    async def ler_url_documento(self, url: str) -> dict[str, Any]:
        """Lê documento já identificado no PJe. Aceita somente URL do domínio TJCE/PJe."""
        if not url.startswith("https://pje.tjce.jus.br/"):
            raise ValueError("URL de documento fora do domínio autorizado do PJe-TJCE")
        async with self._op_lock:
            response = await self.page.request.get(url, timeout=45000)
            if not response.ok:
                raise PJeAdapterError(f"Falha ao ler documento: HTTP {response.status}")
            content_type = (response.headers.get("content-type") or "").lower()
            body = await response.body()
            if "pdf" in content_type or body[:4] == b"%PDF":
                with pdfplumber.open(io.BytesIO(body)) as pdf:
                    text = "\n".join((p.extract_text() or "") for p in pdf.pages)
                return {"tipo": "pdf", "texto": text, "bytes": len(body)}
            text = body.decode("utf-8", errors="replace")
            text = re.sub(r"(?is)<script.*?</script>|<style.*?</style>", " ", text)
            text = re.sub(r"<[^>]+>", " ", text)
            text = re.sub(r"\s+", " ", text).strip()
            return {"tipo": "html", "texto": text, "bytes": len(body)}
