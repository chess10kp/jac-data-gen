"""Given a position on the reference, return the same position relative to the full query sequence."""
def query_position(record: dict[str, int | str], gene: str, reference_position: int) -> int | None {
    ref_pos = (record[gene + "_germline_start"] as int) - 1;
    query_pos = (record[gene + "_sequence_start"] as int) - 1;
    if ref_pos == reference_position { return query_pos; }
    sequence_alignment = record[gene + "_sequence_alignment"] as str;
    germline_alignment = record[gene + "_germline_alignment"] as str;
    for (ref_c, query_c) in zip(germline_alignment, sequence_alignment) {
        if ref_c != "-" { ref_pos += 1; }
        if query_c != "-" { query_pos += 1; }
        if ref_pos == reference_position { return query_pos; }
    }
    return None;
}