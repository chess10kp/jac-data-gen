"""
    Helper function for dealing with the feature values that Stanza returns.
    They look like "Case=Nom|Gender=Fem|Number=Sing" and we convert it to a dictionary with keys "Case" (e.g. "NOM"), "Gender" (e.g. "FEM"), "Number" (e.g. "SIN"). We capitalize the values and make them 3 characters long for compatibility with the notation that is used in Morphy.
    """
def parse_feats(feats: str) -> dict[str, str] {
    pairs = [];
    for pair in feats.split("|") {
        (key, val) = pair.split("=");
        val = val[:3].upper();
        pairs.append((key, val));
    }
    return dict(pairs);
}