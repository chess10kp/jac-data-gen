"""return a list consisting of multiple lists"""
def get_table_tree(form: list[int]) -> list[list] {
    table = [];
    if len(form) {
        while form[0] {
            table.append(get_table_tree(form[1:]));
            form[0] -= 1;
        }
        return table;
    } else {
        return [];
    }
}