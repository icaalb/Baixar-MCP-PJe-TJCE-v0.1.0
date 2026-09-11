import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parents[1] / "src"))

from config import CLIENT_IDS, URL_BASES, normalize_grau


def test_urls_tjce():
    assert URL_BASES["1g"].endswith("/pje1grau")
    assert URL_BASES["2g"].endswith("/pje2grau")
    assert CLIENT_IDS["1g"] == "pje-tjce-1g"
    assert CLIENT_IDS["2g"] == "pje-tjce-2g"


def test_grau():
    assert normalize_grau("1") == "1g"
    assert normalize_grau("2") == "2g"
