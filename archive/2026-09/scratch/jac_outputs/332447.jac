"""Removes corporation suffix from developer names, if present.

    Args:
        dev (str): Name of app developer.

    Returns:
        str: Name of app developer with suffixes stripped.
    """
def strip_dev_suffix(dev: Any) -> object {
    corp_suffixes = (
        "incorporated",
        "corporation",
        "limited",
        "oy/ltd",
        "pty ltd",
        "pty. ltd",
        "pvt ltd",
        "pvt. ltd",
        "s.a r.l",
        "sa rl",
        "sarl",
        "srl",
        "corp",
        "gmbh",
        "l.l.c",
        "inc",
        "llc",
        "ltd",
        "pvt",
        "oy",
        "sa",
        "ab"
    );
    if (dev not in (None, "")) {
        for suffix in corp_suffixes {
            if dev.lower().rstrip(" .").endswith(suffix) {
                dev = dev.rstrip(" .")[:(len(dev) - len(suffix) - 1)].rstrip(",. ");
                break;
            }
        }
    }
    return dev;
}