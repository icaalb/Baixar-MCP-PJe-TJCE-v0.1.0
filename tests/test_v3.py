import asyncio
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from config import VERSION, normalize_grau
from pje_client_v3 import PJeClientV3


def test_version_v3():
    assert VERSION == "0.3.0"


def test_normalize_grau():
    assert normalize_grau("1g") == "1g"
    assert normalize_grau("2g") == "2g"
    assert normalize_grau("apelação") == "2g"


def test_invalid_grau():
    with pytest.raises(ValueError):
        normalize_grau("3g")


def test_client_defaults_to_read_only_browser_mode():
    client = PJeClientV3(grau="2g", headless=False)
    assert client.grau == "2g"
    assert client.is_alive() is False


def test_document_domain_guard():
    client = PJeClientV3(grau="2g", headless=False)

    async def run():
        with pytest.raises(ValueError):
            await client.ler_url_documento("https://example.com/documento.pdf")

    asyncio.run(run())
