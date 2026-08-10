"""Return the BondEthernet by name, if it exists. Return None,None otherwise."""
def get_by_name(yaml: dict[str, dict], ifname: str) -> tuple[str | None, dict | None] {
    try {
        if ifname in yaml["bondethernets"] {
            return (ifname, yaml["bondethernets"][ifname]);
        }
    } except KeyError {
        ;
    }
    return (None, None);
}