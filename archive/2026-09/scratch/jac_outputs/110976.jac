"""Create a mapping from database prefix to database url."""
def get_extra_couchdbs(
    config: list[str | tuple[str, str]],
    couch_database_url: str,
    extra_db_names: tuple[str, ...] = ()
) -> dict[str, str] {
    extra_dbs = {};
    postfixes = [];
    for row in config {
        if isinstance(row, tuple) {
            (_, postfix) = row;
            if postfix {
                postfixes.append(postfix);
            }
        }
    }
    postfixes.extend(extra_db_names);
    for postfix in postfixes {
        extra_dbs[postfix] = '%s__%s' % (couch_database_url, postfix);
    }
    return extra_dbs;
}