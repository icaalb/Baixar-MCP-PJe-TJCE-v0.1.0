from __future__ import annotations

import keyring

from config import KEYRING_SERVICE


def save_credentials(cpf: str, senha: str, totp_seed: str) -> None:
    cpf_digits = "".join(ch for ch in cpf if ch.isdigit())
    if len(cpf_digits) != 11:
        raise ValueError("CPF deve conter 11 dígitos")
    if not senha:
        raise ValueError("Senha não pode ser vazia")
    if not totp_seed.strip():
        raise ValueError("Seed TOTP não pode ser vazia")
    keyring.set_password(KEYRING_SERVICE, "cpf", cpf_digits)
    keyring.set_password(KEYRING_SERVICE, "senha", senha)
    keyring.set_password(KEYRING_SERVICE, "totp_seed", totp_seed.replace(" ", "").strip())


def load_credentials() -> tuple[str, str, str]:
    cpf = keyring.get_password(KEYRING_SERVICE, "cpf")
    senha = keyring.get_password(KEYRING_SERVICE, "senha")
    seed = keyring.get_password(KEYRING_SERVICE, "totp_seed")
    if not all((cpf, senha, seed)):
        raise RuntimeError("Credenciais ausentes. Execute setup_credenciais.py.")
    return cpf, senha, seed
