"""Create a query SELECT * WHERE { <subject> ?p ?o .}"""
def build_describe_query(subject: str) -> dict[str, str | list[dict[str, str]]] {
    return {
        'type': 'bgp',
        'bgp': [{'subject': subject, 'predicate': '?p', 'object': '?o'}]
    };
}