"""Replace placeholders in pattern to build path to be scraped."""
def build_path(pattern: str, keys: list[str]) -> str {
    substitutions = {
        "practice_code": "L83100",
        "ccg_code": "15N",
        "stp_code": "E54000037",
        "regional_team_code": "Y58",
        "bnf_code": "0205051R0BBAIAN",
        "measure": "ace"
    };
    path = pattern;
    for key in keys {
        subst_key = None;
        if key in ("code", "entity_code") {
            for token in ("practice", "ccg", "stp", "regional-team") {
                if token in pattern {
                    subst_key = "{}_code".format(token).replace("-", "_");
                }
            }
            if subst_key is None {
                subst_key = "bnf_code";
            }
        } else {
            subst_key = key;
        }
        path = path.replace("%({})s".format(key), substitutions[subst_key]);
    }
    assert "%" not in path, "Could not interpolate " + pattern;
    return path;
}