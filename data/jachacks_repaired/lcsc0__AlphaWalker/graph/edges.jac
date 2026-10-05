"""Graph edge definitions for AlphaWalker."""

edge BelongsToPortfolio {}

edge HasCoalition {
    has side: str = "";
}

edge HasSnapshot {}

edge HasVerdict {}

edge HasAnnotation {}

edge HasRebalance {}
