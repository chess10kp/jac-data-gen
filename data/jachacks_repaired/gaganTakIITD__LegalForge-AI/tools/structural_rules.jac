"""Cross-clause structural rules -- deterministic, not LLM fallbacks."""

def has_liability_cap(text: str) -> bool {
    t = text.lower();
    if "liability" not in t {
        return False;
    }
    return "shall not exceed" in t or ("cap" in t and "$" in t) or "aggregate liability" in t;
}

def has_uncapped_indemnity(text: str) -> bool {
    t = text.lower();
    if "indemnif" not in t {
        return False;
    }
    if "no cap" in t or "without limit" in t or "uncapped" in t or "unlimited" in t {
        return True;
    }
    return ("all losses" in t or "indefinitely" in t) and "cap" not in t;
}

def has_indemnity_cap(text: str) -> bool {
    t = text.lower();
    if "indemnif" not in t {
        return False;
    }
    return "cap" in t or "limited to" in t or "total purchase price" in t;
}

def detect_liability_indemnity_conflict(text_a: str, kind_a: str, text_b: str, kind_b: str) -> dict {
    cap_text = "";
    ind_text = "";
    if kind_a == "liability" and kind_b == "indemnification" {
        cap_text = text_a;
        ind_text = text_b;
    } elif kind_b == "liability" and kind_a == "indemnification" {
        cap_text = text_b;
        ind_text = text_a;
    } else {
        if has_liability_cap(text_a) {
            cap_text = text_a;
        } elif has_liability_cap(text_b) {
            cap_text = text_b;
        }
        if has_uncapped_indemnity(text_a) {
            ind_text = text_a;
        } elif has_uncapped_indemnity(text_b) {
            ind_text = text_b;
        }
    }
    if not cap_text or not ind_text {
        return {};
    }
    if not has_liability_cap(cap_text) or not has_uncapped_indemnity(ind_text) {
        return {};
    }
    return {
        "contradicts": True,
        "severity": "direct",
        "explanation": "Liability is capped but indemnification is uncapped -- indemnity can exceed the liability limit.",
        "confidence": 0.94,
        "rule": "liability_cap_vs_uncapped_indemnity"
    };
}

def detect_ownership_conflict(text_a: str, text_b: str) -> dict {
    parties_a = ["client", "buyer", "developer", "vendor"];
    targets = ["the work", "work product", "deliverables"];
    for p1 in parties_a {
        for p2 in parties_a {
            if p1 == p2 {
                continue;
            }
            for tgt in targets {
                owns1 = (p1 in text_a.lower() and "own" in text_a.lower() and tgt in text_a.lower());
                owns2 = (p2 in text_b.lower() and "own" in text_b.lower() and tgt in text_b.lower());
                if owns1 and owns2 {
                    return {
                        "contradicts": True,
                        "severity": "direct",
                        "explanation": f"Opposing ownership of {tgt}: {p1} vs {p2}.",
                        "confidence": 0.97,
                        "rule": "ownership_literal"
                    };
                }
            }
        }
    }
    return {};
}

def detect_indemnity_cap_conflict(text_a: str, kind_a: str, text_b: str, kind_b: str) -> dict {
    broad = "";
    capped = "";
    if kind_a == "indemnification" and kind_b == "indemnification" {
        if has_broad_indemnity(text_a) and has_indemnity_cap(text_b) {
            broad = text_a;
            capped = text_b;
        } elif has_broad_indemnity(text_b) and has_indemnity_cap(text_a) {
            broad = text_b;
            capped = text_a;
        }
    }
    if not broad or not capped {
        return {};
    }
    return {
        "contradicts": True,
        "severity": "direct",
        "explanation": "Broad indemnification for all losses conflicts with a separate indemnification cap.",
        "confidence": 0.92,
        "rule": "indemnity_cap_internal_conflict"
    };
}

def has_broad_indemnity(text: str) -> bool {
    t = text.lower();
    if "indemnif" not in t {
        return False;
    }
    if has_indemnity_cap(text) {
        return False;
    }
    return "all losses" in t or "indefinitely" in t or has_uncapped_indemnity(text);
}

def detect_termination_noncompete_conflict(text_a: str, kind_a: str, text_b: str, kind_b: str) -> dict {
    term_text = "";
    nc_text = "";
    if kind_a == "termination" and kind_b == "non_compete" {
        term_text = text_a;
        nc_text = text_b;
    } elif kind_b == "termination" and kind_a == "non_compete" {
        term_text = text_b;
        nc_text = text_a;
    } else {
        return {};
    }
    t = term_text.lower();
    if "terminat" not in t {
        return {};
    }
    n = nc_text.lower();
    if "non-compete" not in n and "noncompete" not in n and "non compete" not in n {
        return {};
    }
    if "without severance" in t or "at-will" in t or "at will" in t or "immediately" in t {
        return {
            "contradicts": True,
            "severity": "direct",
            "explanation": "At-will termination right pulls against a long-tail non-compete obligation.",
            "confidence": 0.90,
            "rule": "termination_vs_noncompete"
        };
    }
    return {};
}

def adjudicate_structural_pair(text_a: str, kind_a: str, text_b: str, kind_b: str) -> dict {
    r = detect_ownership_conflict(text_a, text_b);
    if r {
        return r;
    }
    r = detect_termination_noncompete_conflict(text_a, kind_a, text_b, kind_b);
    if r {
        return r;
    }
    r = detect_indemnity_cap_conflict(text_a, kind_a, text_b, kind_b);
    if r {
        return r;
    }
    r = detect_liability_indemnity_conflict(text_a, kind_a, text_b, kind_b);
    if r {
        return r;
    }
    return {};
}
