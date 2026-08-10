"""Choose derived or type dispatch strategy for a declaration."""
def dispatch_strategy(declaration: dict[str, bool | str | None]) -> str {
    if declaration['abstract'] or declaration['derivative'] is not None {
        return 'use_derived';
    }
    return 'use_type';
}