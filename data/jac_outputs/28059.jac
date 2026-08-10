"""Remove hostnames that do not end with any of the target scope domains."""
def remove_unrelated_domains(subdomains: list[str], domains: list[str]) -> list[str] {
    return [s for s in subdomains if s.endswith(tuple(domains))];
}