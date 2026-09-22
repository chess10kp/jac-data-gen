"""
    This function is used to sort the domains in a hierarchical order for
    readability.

    Args:
    domains -- the list of input domains

    Returns:
    domains -- hierarchically sorted list of domains
    """
def sort_domains(domains: Any) -> object {
    domainbits = [domain.lower().split('.') for domain in domains];
    for domain in domainbits {
        domain.reverse();
    }
    sorted(domainbits);
    domains = ['.'.join(reversed(domain)) for domain in sorted(domainbits)];
    return domains;
}