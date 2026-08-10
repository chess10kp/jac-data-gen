"""Check if the MCLAG session timeout in valid range (between 3 and 3600)"""
def mclag_session_timeout_valid(session_tmout: int) -> tuple[bool, str] {
    if session_tmout < 3 or session_tmout > 3600 {
        return (False, "Session timeout %s not in valid range[3-3600]" % session_tmout);
    }
    return (True, "");
}