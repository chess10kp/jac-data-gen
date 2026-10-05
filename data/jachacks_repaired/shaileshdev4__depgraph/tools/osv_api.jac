"""OSV.dev vulnerability lookup (accurate per ecosystem + version)."""

import from tools.ecosystem_util { osv_ecosystem_for }
import from tools.env_util { ensure_dotenv_loaded }
import from tools.jac_coerce { as_list }

sem osv_query_npm = "Query OSV for npm package@version; returns normalized CVE dicts.";
sem osv_query_ecosystem = "Query OSV for any supported DepGraph ecosystem.";

glob osv_cache: dict[str, list[dict]] = {};

def _severity_from_score(score: float) -> str {
    if score >= 9.0 {
        return "CRITICAL";
    }
    if score >= 7.0 {
        return "HIGH";
    }
    if score >= 4.0 {
        return "MEDIUM";
    }
    if score > 0.0 {
        return "LOW";
    }
    return "UNKNOWN";
}

def _score_from_severity_label(label: str) -> float {
    u = str(label).strip().upper();
    if u == "CRITICAL" {
        return 9.8;
    }
    if u == "HIGH" {
        return 8.1;
    }
    if u == "MODERATE" {
        return 5.5;
    }
    if u == "MEDIUM" {
        return 5.5;
    }
    if u == "LOW" {
        return 3.1;
    }
    return 0.0;
}

def _extract_fixed_version(item: dict) -> str {
    affected_list = as_list(item.get("affected", []));
    for affected in affected_list {
        if not isinstance(affected, dict) {
            continue;
        }
        ranges = as_list(affected.get("ranges", []));
        for range_ in ranges {
            if not isinstance(range_, dict) {
                continue;
            }
            events = as_list(range_.get("events", []));
            for event in events {
                if not isinstance(event, dict) {
                    continue;
                }
                if "fixed" in event {
                    fixed = str(event["fixed"]);
                    if fixed and fixed != "0" {
                        return fixed;
                    }
                }
            }
        }
    }
    return "";
}

def _osv_query_raw(
    package_name: str,
    version: str,
    osv_ecosystem: str
) -> list[dict] {
    cache_key = f"{osv_ecosystem}:{package_name.lower()}@{version}";
    if cache_key in osv_cache {
        return osv_cache[cache_key];
    }

    ensure_dotenv_loaded();
    import requests;

    url = "https://api.osv.dev/v1/query";
    payload = {
        "package": {"name": package_name, "ecosystem": osv_ecosystem},
        "version": version
    };
    resp = requests.post(url, json=payload, timeout=30);
    if resp.status_code != 200 {
        osv_cache[cache_key] = [];
        return [];
    }
    body = resp.json();
    vulns = as_list(body.get("vulns", []));
    results: list[dict] = [];
    for item in vulns {
        if not isinstance(item, dict) {
            continue;
        }
        cve_id = str(item.get("id", ""));
        aliases = as_list(item.get("aliases", []));
        for alias in aliases {
            alias_str = str(alias);
            if alias_str.startswith("CVE-") {
                cve_id = alias_str;
                break;
            }
        }
        if not cve_id {
            continue;
        }
        score = 0.0;
        db = item.get("database_specific", {});
        if isinstance(db, dict) {
            if "cvss_score" in db {
                try {
                    score = float(str(db["cvss_score"]));
                } except Exception {}
            }
            if score <= 0.0 and "severity" in db {
                label_score = _score_from_severity_label(str(db["severity"]));
                if label_score > score {
                    score = label_score;
                }
            }
        }
        severities = as_list(item.get("severity", []));
        for sev in severities {
            if not isinstance(sev, dict) {
                continue;
            }
            if "score" not in sev {
                continue;
            }
            raw = str(sev["score"]).strip();
            if not raw {
                continue;
            }
            cvss_prefix = "CVSS";
            if raw.startswith(cvss_prefix) {
                continue;
            }
            try {
                candidate = float(raw);
                if candidate > score {
                    score = candidate;
                }
            } except Exception {}
        }
        if score <= 0.0 {
            ecosystem_specific = item.get("ecosystem_specific", {});
            if isinstance(ecosystem_specific, dict) {
                sev_label = str(ecosystem_specific.get("severity", ""));
                if sev_label {
                    label_score = _score_from_severity_label(sev_label);
                    if label_score > 0.0 {
                        score = label_score;
                    }
                }
            }
        }
        summary = str(item.get("summary", ""));
        if not summary {
            details = str(item.get("details", ""));
            summary = details[0:500];
        }
        results.append(
            {
                "cve_id": cve_id,
                "cvss_score": score,
                "severity": _severity_from_score(score),
                "description": summary[0:500],
                "fixed_version": _extract_fixed_version(item),
                "source": "osv"
            }
        );
    }
    osv_cache[cache_key] = results;
    return results;
}

def osv_query_npm(package_name: str, version: str) -> list[dict] {
    return _osv_query_raw(package_name, version, "npm");
}

def osv_query_ecosystem(
    package_name: str,
    version: str,
    depgraph_ecosystem: str
) -> list[dict] {
    osv_eco = osv_ecosystem_for(depgraph_ecosystem);
    return _osv_query_raw(package_name, version, osv_eco);
}
