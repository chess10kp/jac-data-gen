"""Determine if column is a concept_id column."""
def is_concept_id_col(col: str) -> bool {
    return col.endswith('concept_id');
}