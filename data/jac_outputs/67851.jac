"""Takes a table string (like that from a CLI command) and
returns a list of records matching the header to values."""
def cli_table_to_recs(table_string: str) -> list[dict[str, str]] {
    lines = table_string.split('\n');
    header_line = lines.pop(0).split();
    route_recs = [];
    for line in lines {
        vals = line.split();
        rec = dict(zip(header_line, vals));
        route_recs.append(rec);
    }
    return route_recs;
}