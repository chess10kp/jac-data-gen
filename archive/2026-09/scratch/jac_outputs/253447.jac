"""Display confirm msg (Green)."""
def confirm(cause: str) -> str {
    return "\033[1;32;40m [+] " + cause + " \033[0m ";
}