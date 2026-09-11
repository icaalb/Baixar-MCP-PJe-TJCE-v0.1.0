from getpass import getpass
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent / "src"))
from security import save_credentials


def main() -> None:
    print("Configuração segura do MCP PJe-TJCE")
    print("As credenciais serão gravadas no cofre de credenciais do sistema operacional.")
    cpf = input("CPF: ").strip()
    senha = getpass("Senha PDPJ/PJe: ")
    seed = getpass("Seed TOTP (Base32): ")
    save_credentials(cpf, senha, seed)
    print("Credenciais armazenadas com sucesso.")


if __name__ == "__main__":
    main()
