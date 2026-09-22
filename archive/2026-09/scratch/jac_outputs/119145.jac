"""Mock a processed token."""
def mock_token(bona_fide: bool, permissions: list[str], auth: bool) -> dict[str, bool | list[str]] {
    return {
        "bona_fide_status": bona_fide,
        "permissions": permissions,
        "authenticated": auth
    };
}