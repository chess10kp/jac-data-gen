"""Search for identical chains to chain_name already included in the complex."""
def PossibleChains(equivalences: dict[str, list[str]], fixed_names: list[str], chain_name: str) -> list[str] {
    return [
        element
        for chain in equivalences
        if chain_name in equivalences[chain]
        for element in equivalences[chain]
        if element in fixed_names
    ];
}