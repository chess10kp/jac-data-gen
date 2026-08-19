def complete_example(
    pos_only1: int,           # 1. Positional-only parameters
    pos_only2: str,
    /,                         # 2. Positional-only marker
    pos_or_kw: float,          # 3. Normal (positional-or-keyword)
    with_default: int = 10,    # 4. Parameters with defaults
    *args: int,                # 5. Variadic positional
    kw_only: str,              # 6. Keyword-only (after * or *args)
    kw_default: bool = True,   # 7. Keyword-only with default
    **kwargs: object           # 8. Variadic keyword (must be last)
) -> None {
    print("called");
}
