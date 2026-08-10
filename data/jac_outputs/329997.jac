"""Convert string to int, allowing unit suffixes.

    This is used as 'type' for argparse.ArgumentParser.
    """
def intWithUnit(s: Any) -> object {
    if (len(s) == 0) {
        return int(s);
    }
    index = "BkMGTPE".find(s[-1]);
    if (index >= 0) {
        return int((float(s[:-1]) * (1 << (index * 10))));
    } else {
        return int(s);
    }
}