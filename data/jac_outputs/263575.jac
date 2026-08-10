"""Sanitize sensitive request headers for logging."""
def sanitize_headers(headers: dict[str, str]) -> dict[str, str] {
    results = dict(headers);
    if results.get('Authorization') {
        results['Authorization'] = '***redacted***';
    }
    return results;
}