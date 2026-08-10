"""Check if coarse parallel is enabled as expected."""
def check_coarse_parallel(msgs: list[str]) -> bool {
    for msg in msgs {
        if msg.find('"coarse_grained_parallel": "off') != -1 {
            return False;
        }
    }
    return True;
}