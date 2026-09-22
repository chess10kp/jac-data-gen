"""
    Return the name of the index from the create index statement.
    """
def get_index_name(create_index_statement: str, unique_constraint: bool) -> str {
    splitted_statement = create_index_statement.split(' ', 6);
    if unique_constraint {
        if "." in splitted_statement[3] {
            index_name = splitted_statement[3].split('.')[1];
        } else {
            index_name = splitted_statement[3];
        }
    } elif "." in splitted_statement[2] {
        index_name = splitted_statement[2].split('.')[1];
    } else {
        index_name = splitted_statement[2];
    }
    return index_name;
}