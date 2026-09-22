"""Build CREATE TABLE SQL from field names and source table."""
def create_table_sql(flds2keep: list[str], table: str) -> str {
    fld_names = ["[{}]".format(x) for x in flds2keep];
    fld_list = ", ".join(fld_names);
    return "create table tmp as select {} from [{}];".format(fld_list, table);
}