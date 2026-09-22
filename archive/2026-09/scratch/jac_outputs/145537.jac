"""Process data from sw_interface_dump API and return index of the interface specified by name."""
def get_interface_index_from_api(data: list[dict[str, dict[str, str | int]]], name: str) -> int {
    for iface in data {
        if iface["sw_interface_details"]["interface_name"] == name {
            return iface["sw_interface_details"]["sw_if_index"] as int;
        }
    }
    raise RuntimeError(
        f"Interface with name {name} not found in dump. Dumped data: {data}"
    );
}