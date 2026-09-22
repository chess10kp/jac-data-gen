"""Convert python compatible name to Transmission RPC name."""
def make_rpc_name(name: str) -> str {
    return name.replace("_", "-");
}