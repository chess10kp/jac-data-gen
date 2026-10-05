"""In-memory risk scoring for dependency prioritization (no API calls)."""

import from tools.jac_coerce { as_list }

glob HIGH_RISK_KEYWORDS: list[str] = [
    "jwt", "auth", "crypto", "passport", "bcrypt", "serialize",
    "eval", "exec", "shell", "xml", "yaml", "parse", "request",
    "axios", "express", "lodash", "moment", "vm2", "node-serialize",
    "log4", "token", "cookie", "session", "oauth", "ssl", "tls",
    "https", "http", "fetch", "got", "request", "body-parser"
];

def _name_has_high_risk_keyword(name: str) -> bool {
    name_lower = name.lower();
    for kw in HIGH_RISK_KEYWORDS {
        if kw in name_lower {
            return True;
        }
    }
    return False;
}

def _major_version_bonus(version: str) -> int {
    ver = str(version).strip();
    if not ver {
        return 0;
    }
    parts = ver.split(".");
    if not parts {
        return 0;
    }
    major_str = parts[0];
    try {
        major = int(major_str);
    } except Exception {
        return 0;
    }
    if major == 0 {
        return 40;
    }
    if major == 1 {
        return 20;
    }
    if major == 2 {
        return 10;
    }
    return 0;
}

def package_risk_score(
    name: str,
    version: str,
    depth: int,
    is_direct: bool
) -> int {
    score = 0;
    if depth == 0 {
        score += 100;
    } elif depth == 1 {
        score += 80;
    } else {
        depth_bonus = 10 - depth;
        if depth_bonus > 0 {
            score += depth_bonus * 10;
        }
    }
    if _name_has_high_risk_keyword(name) {
        score += 50;
    }
    score += _major_version_bonus(version);
    if is_direct {
        score += 15;
    }
    return score;
}

def filter_top_risk_packages(
    packages: list[dict],
    edges: list[dict],
    max_packages: int = 200
) -> dict {
    pkg_count = len(packages);
    if pkg_count <= max_packages {
        return {
            "packages": packages,
            "edges": edges,
            "truncated": False,
            "original_package_count": pkg_count,
            "method": "none"
        };
    }
    key_to_score: dict = {};
    for pkg in packages {
        pkg_key = str(pkg["key"]);
        pkg_depth = 0;
        if "depth" in pkg {
            pkg_depth = int(pkg["depth"]);
        }
        pkg_direct = False;
        if "is_direct" in pkg {
            pkg_direct = bool(pkg["is_direct"]);
        }
        key_to_score[pkg_key] = package_risk_score(
            str(pkg["name"]),
            str(pkg["version"]),
            pkg_depth,
            pkg_direct
        );
    }
    selected: list[dict] = [];
    selected_keys: dict = {};
    picks = 0;
    while picks < max_packages {
        best_key = "";
        best_score = -1;
        for pkg_key in key_to_score {
            if pkg_key in selected_keys {
                continue;
            }
            entry_score = key_to_score[pkg_key];
            if entry_score > best_score {
                best_score = entry_score;
                best_key = pkg_key;
            }
        }
        if not best_key {
            break;
        }
        for pkg in packages {
            if str(pkg["key"]) == best_key {
                selected.append(pkg);
                break;
            }
        }
        selected_keys[best_key] = True;
        picks += 1;
    }
    kept_edges: list[dict] = [];
    for edge in edges {
        from_key = str(edge["from_key"]);
        to_key = str(edge["to_key"]);
        if from_key in selected_keys and to_key in selected_keys {
            kept_edges.append(edge);
        }
    }
    return {
        "packages": selected,
        "edges": kept_edges,
        "truncated": True,
        "original_package_count": pkg_count,
        "method": "risk_score"
    };
}
