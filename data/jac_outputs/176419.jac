"""Generate a str with concatenation of given list of vm name."""
def generate_vm_name_str(vms: list[str]) -> str {
    return ",".join(vms);
}