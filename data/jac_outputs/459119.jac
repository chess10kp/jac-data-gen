"""Lookup package licenses"""
def bulk_lookup(license_dict: dict[str, str], pkg_list: list[dict[str, str | list[str] | None]]) -> dict[str, list[str]] {
    pkg_licenses: dict[str, list[str]] = {};
    for pkg in pkg_list {
        if not pkg.get("name") or not pkg.get("version") {
            continue;
        }
        pkg_key = (pkg["name"] as str) + "@" + (pkg["version"] as str);
        if pkg.get("vendor") {
            pkg_key = (pkg.get("vendor") as str) + ":" + (pkg["name"] as str) + "@" + (pkg["version"] as str);
        }
        for lic in (pkg.get("licenses") as list[str]) {
            if lic == "X11" {
                lic = "MIT";
            } elif "MIT" in lic {
                lic = "MIT";
            }
            curr_list = pkg_licenses.get(pkg_key, []);
            match_lic = license_dict.get(lic);
            if match_lic {
                curr_list.append(match_lic);
            }
            pkg_licenses[pkg_key] = curr_list;
        }
    }
    return pkg_licenses;
}