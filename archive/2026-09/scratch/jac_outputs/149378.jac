"""Returns a list of headers in an sql select string"""
def get_headers(sql: str, prefix: str | None = None) -> list[str] | str {
    cols: list[str] = [];
    open_parenth = False;
    clean_sql = "";
    for (i, char) in enumerate(sql) {
        if char == "(" {
            open_parenth = True;
        } elif char == ")" {
            open_parenth = False;
        }
        if not open_parenth {
            clean_sql += sql[i].replace("\t", " ");
        }
    }
    for col in clean_sql.split("FROM")[0].replace("SELECT", "").split(",") {
        if " as " in col.lower() {
            c = col.split(" as ")[-1];
        } elif "." in col.lower() {
            c = col.split(".")[-1];
        } else {
            c = col;
        }
        cols.append(c.strip());
    }
    if prefix != None {
        return ", ".join([".".join([prefix, col]) for col in cols]);
    }
    return cols;
}