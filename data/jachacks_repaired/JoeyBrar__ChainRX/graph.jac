"""Graph definitions for ChainRX drug interaction detector."""

node Drug {
    has name: str,
        is_flagged: bool = False;
}

edge InteractsWith {
    has interaction_type: str,
        mechanism: str,
        severity: float;
}
