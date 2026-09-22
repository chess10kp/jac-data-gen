"""Remove id fields from resultset."""
def _filter_id(dict_dirty: dict[str, object]) -> dict[str, object] {
    return dict(
        filter(
            lambda (elem: tuple[str, object]) { elem[0][-3:] != "_id" and elem[0] != "id"; },
            dict_dirty.items()
        )
    );
}