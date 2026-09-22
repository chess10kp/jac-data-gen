"""process block device info returned by device-scanner to produce
a legacy version of local mounts
"""
def parse_local_mounts(xs: list[dict[str, str]]) -> list[tuple[str, str, str]] {
    return [(d["source"], d["target"], d["fs_type"]) for d in xs];
}