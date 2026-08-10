"""Find a deployment unit id associated with an ip."""
def find_du_based_on_ip(ip: str, functions: list[dict[str, str | dict[str, str | list[dict[str, str]]]]]) -> tuple[str | None, str | None] {
    for vnf in functions {
        if 'vnfr' not in vnf.keys() {
            continue;
        }
        vnfr = vnf['vnfr'] as dict[str, str | list[dict[str, str]]];
        dus: list[dict[str, str]] = [];
        if 'virtual_deployment_units' in vnfr.keys() {
            dus = vnfr['virtual_deployment_units'] as list[dict[str, str]];
        }
        if 'couldnative_deployment_units' in vnfr.keys() {
            dus = vnfr['cloudnative_deployment_units'] as list[dict[str, str]];
        }
        for du in dus {
            du_string = str(du);
            if ip in du_string {
                return (du['id'], vnf['id'] as str);
            }
        }
    }
    return (None, None);
}