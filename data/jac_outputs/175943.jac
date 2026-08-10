"""Get key for out channel and in channel combination in the solution."""
def get_component_key(out_chan: str, in_chan: str) -> str {
    return f"{out_chan}{in_chan}";
}