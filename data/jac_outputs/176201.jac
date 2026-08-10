"""Extract conflict licenses from license analysis REST service output.

Returns a list of pairs of packages whose licenses are in conflict.
Only available when each component license was identified and there
was a stack level license conflict."""
def _extract_conflict_packages(license_service_output: dict[str, object] | None) -> list[dict[str, str]] {
    license_conflict_packages: list[dict[str, str]] = [];
    if not license_service_output {
        return license_conflict_packages;
    }
    conflict_packages = license_service_output.get('conflict_packages', []) as list[dict[str, str]];
    for conflict_pair in conflict_packages {
        list_pkgs = list(conflict_pair.keys());
        assert len(list_pkgs) == 2;
        d = {
            "package1": list_pkgs[0],
            "license1": conflict_pair[list_pkgs[0]],
            "package2": list_pkgs[1],
            "license2": conflict_pair[list_pkgs[1]]
        };
        license_conflict_packages.append(d);
    }
    return license_conflict_packages;
}