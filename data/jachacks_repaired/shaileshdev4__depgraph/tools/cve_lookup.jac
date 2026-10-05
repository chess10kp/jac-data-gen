"""Unified CVE lookup: OSV for npm, filtered NVD fallback."""

import from tools.nvd_api { nvd_search_cve }
import from tools.osv_api { osv_query_ecosystem }

sem lookup_package_cves = "Return CVE dicts for a package; prefers OSV when version is known.";

def lookup_package_cves(
    package_name: str,
    version: str,
    ecosystem: str = "npm"
) -> list[dict] {
    eco = str(ecosystem).lower();
    if eco == "auto" {
        eco = "npm";
    }
    if version and eco in ["npm", "pypi", "go", "maven"] {
        osv_hits = osv_query_ecosystem(package_name, version, eco);
        if osv_hits {
            return osv_hits;
        }
        return [];
    }
    return nvd_search_cve(package_name, version, ecosystem);
}
