def search_string_from_terms(include_terms: list[str], exclude_terms: list[str] | None) -> str {
    marked_exclude_terms = ['-' + term for term in (exclude_terms or [])];
    return ' '.join(list(include_terms) + marked_exclude_terms);
}