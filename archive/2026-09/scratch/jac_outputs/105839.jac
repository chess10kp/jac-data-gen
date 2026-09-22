"""Orders column list with primary keys first, then non-primary key columns."""
def order_columns(pks: list[str], columns: list[dict[str, object]]) -> list[dict[str, object]] {
    pk_list = [];
    non_pk_list = [];
    for c in columns {
        if any(c.get("name") == pk for pk in pks) {
            pk_list.append(c);
        } else {
            non_pk_list.append(c);
        }
    }
    return pk_list + non_pk_list;
}