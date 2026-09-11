from __future__ import annotations

import os
from pathlib import Path

TRIBUNAL = "TJCE"
MCP_NAME = "pje-tjce"
KEYRING_SERVICE = "mcp-pje-tjce"

URL_BASES = {
    "1g": "https://pje.tjce.jus.br/pje1grau",
    "2g": "https://pje.tjce.jus.br/pje2grau",
}

CLIENT_IDS = {
    "1g": "pje-tjce-1g",
    "2g": "pje-tjce-2g",
}

DEFAULT_GRAU = os.getenv("PJE_TJCE_GRAU", "2g")
HEADLESS = os.getenv("PJE_HEADLESS", "1") == "1"
WARMUP = os.getenv("PJE_WARMUP", "0") == "1"
IDLE_TIMEOUT_SECONDS = int(os.getenv("PJE_IDLE_TIMEOUT", "300"))
PROFILE_HINT = os.getenv("PJE_TJCE_PROFILE_HINT", "").strip()
DOWNLOAD_ROOT = Path(os.getenv("PJE_TJCE_DOWNLOAD_ROOT", str(Path.home() / "PJe TJCE"))).expanduser()


def normalize_grau(grau: str | None) -> str:
    if not grau:
        return DEFAULT_GRAU if DEFAULT_GRAU in URL_BASES else "2g"
    value = str(grau).strip().lower()
    if value in {"2", "2g", "segundo", "segundo grau", "tribunal", "tj", "apelação", "apelacao"}:
        return "2g"
    if value in {"1", "1g", "primeiro", "primeiro grau"}:
        return "1g"
    raise ValueError("grau deve ser '1g' ou '2g'")
