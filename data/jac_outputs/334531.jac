"""Parses the users id from the users banner photo url."""
def parse_user_id_from_banner(banner_url: str) -> str {
    banner_url.split("%2F")[1]
}