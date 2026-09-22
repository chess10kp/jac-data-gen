"""Determines whether CVE is about system."""
def cve_is_about_system(cpe_type: str) -> bool {
    return ('o' in cpe_type or 'h' in cpe_type) and 'a' not in cpe_type;
}