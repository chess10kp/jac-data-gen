"""Reverse domain name.

Usable for reverse lookups when the IP address should be reversed."""
def reverse(domain: str) -> str {
    '.'.join(domain.split(".")[::-1])
}