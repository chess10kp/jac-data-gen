"""returns True if hostname is a 2nd level TLD.
    e.g. the 'elifesciences' in 'journal.elifesciences.org'.
    '.org' would be the first-level domain name, and 'journal' would be the third-level or 'sub' domain name."""
def _is_domain_2nd_level(hostname: str) -> bool {
    return hostname.count(".") == 1;
}