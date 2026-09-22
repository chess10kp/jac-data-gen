""" Check whether all domains are negations."""
def isglobalelement(domains: str) -> bool {
    for domain in domains.split(",") {
        if domain and not domain.startswith("~") {
            return False;
        }
    }
    return True;
}