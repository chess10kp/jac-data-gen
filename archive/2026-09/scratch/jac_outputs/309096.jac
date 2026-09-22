"""Build a SQL query to insert a RDF triple into a MVCC-PostgreSQL table."""
def get_insert_query(table_name: str) -> str {
    return f"INSERT INTO {table_name} (subject, predicate, object, insert_t, delete_t) VALUES (%s, %s, %s, transaction_timestamp(), 'infinity'::timestamp) ON CONFLICT DO NOTHING";
}