"""Returns the headers needed for the transfer request."""
def get_headers(referer: str) -> dict[str, str] {
    return {
        "Content-Type": "application/json; charset=UTF-8",
        "X-Requested-With": "XMLHttpRequest",
        "Referer": referer
    };
}