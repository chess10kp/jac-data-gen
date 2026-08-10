"""Count number of vulnerabilities in depscan output."""
def count_vulns(data: str) -> tuple[int, int, int] {
    high = data.count('"severity": "HIGH"');
    high += data.count('"severity": "CRITICAL"');
    med = data.count('"severity": "MEDIUM"');
    low = data.count('"severity": "LOW"');
    return (high, med, low);
}