"""Insert polynomial root data into an SQL database."""
def insert_row(order: int) -> str {
    params = ', '.join(
        ["root{}, iroot{}".format(i, i) for i in range(order)]
    );
    inserts = ', '.join(["?, ?" for i in range(order)]);
    query = "INSERT OR REPLACE INTO polynomials (id, {}) VALUES (?, {})".format(
        params, inserts
    );
    return query;
}