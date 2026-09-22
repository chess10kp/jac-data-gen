""" in:  {"Col1":1, "Col2":2}
        out: (
              "Col1 = %s AND Col2 = %s",
              [1, 2]
             )
    """
def format_dict_where_to_sql(ColsSearch: dict[str, object]) -> tuple[str, list[object]] {
    sqls = [];
    values = [];
    for (col, value) in ColsSearch.items() {
        sqls.append("`{}` = %s".format(col));
        values.append(value);
    }
    sql = " AND ".join(sqls);
    return (sql, values);
}