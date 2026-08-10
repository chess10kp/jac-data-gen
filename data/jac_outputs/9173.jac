"""Translate"""
def xlate(vname: str) -> str {
    if vname in ("ws_10m_nw", "ws_40m_nw", "ws_120m_nw") {
        return vname + "ht";
    }
    return vname;
}