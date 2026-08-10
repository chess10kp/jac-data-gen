"""Returns int (or None on failure)

Finds the target migration version by its version string (not sortable version) in the list of migrations
"""
def find_migration_file_version(
    config: object,
    migrations: list[dict[str, object]],
    version: str,
    prior: bool = False
) -> int | None {
    ix = None;
    for (ix, m) in enumerate(migrations) {
        if m['version'] == version {
            return ix;
        }
    }
    if prior {
        return ix;
    }
    return None;
}