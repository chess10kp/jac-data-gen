"""Group mod."""
def group_mod(
    group_id: int | str,
    gtype: str,
    buckets: list[str]
) -> dict[str, int | str | list[str]] {
    return dict(
        `type=gtype,
        group_id=group_id,
        buckets=buckets() if callable(buckets) else buckets
    );
}