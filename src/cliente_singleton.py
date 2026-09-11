from __future__ import annotations

import asyncio
import time
from typing import Optional

from config import HEADLESS, IDLE_TIMEOUT_SECONDS, normalize_grau
from pje_client import Credentials, PJeClient
from security import load_credentials

_client: Optional[PJeClient] = None
_active_grau: Optional[str] = None
_last_use = 0.0
_lock = asyncio.Lock()


async def get_client(grau: str = "2g") -> PJeClient:
    global _client, _active_grau, _last_use
    g = normalize_grau(grau)
    async with _lock:
        now = time.time()
        alive = bool(_client and _client._browser and _client._browser.is_connected())
        if alive and _active_grau == g and now - _last_use < IDLE_TIMEOUT_SECONDS:
            _last_use = now
            return _client  # type: ignore[return-value]
        if _client:
            try:
                await _client.close()
            except Exception:
                pass
        cpf, senha, seed = load_credentials()
        _client = PJeClient(Credentials(cpf, senha, seed), grau=g, headless=HEADLESS)
        await _client.start()
        _active_grau = g
        _last_use = now
        return _client


async def close_client() -> None:
    global _client, _active_grau, _last_use
    async with _lock:
        if _client:
            try:
                await _client.close()
            finally:
                _client = None
                _active_grau = None
                _last_use = 0.0


async def close_if_idle() -> bool:
    global _client, _active_grau
    async with _lock:
        if not _client or time.time() - _last_use < IDLE_TIMEOUT_SECONDS:
            return False
        await _client.close()
        _client = None
        _active_grau = None
        return True
