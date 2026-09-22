"""Transforma os valores dos club
DIAMANTE -> 1
OURO -> 2
PRATA -> 3
BRONZE -> 4
"""
def handle_club(input: str) -> int {
    match input {
        case "DIAMANTE":
            return 1;
        case "OURO":
            return 2;
        case "PRATA":
            return 3;
        case "BRONZE":
            return 4;
        case _:
            raise ValueError(f"Club ({input}) desconhecido, verifique");
    }
}