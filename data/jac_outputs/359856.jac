"""
    finds a relevant predecessor row in a batch
    """
def find_predecessor_row_from_batch(
    parsed_rows: Any, batch_row_id: Any, predecessor_name: Any
) -> object {
    batch_rows = filter(
        lambda (x: Any) { (x['parent_id'] == batch_row_id); }, parsed_rows
    );
    for row in batch_rows {
        if (row['name'] == predecessor_name) {
            return row;
        }
    }
    return None;
}