"""Replaces ' ' for  '+'"""
def query_encode(query: str) -> str {
    return query.replace(" ", "+");
}