"""See RFC 2631 section 2.1.5."""
def dh_validate_public(public: Any, q: Any, p: Any) -> object {
    return (1 == pow(public, q, p));
}