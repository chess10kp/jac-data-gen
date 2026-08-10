"""
Snaps the width of each column of the table to the width of the
largest element in the respective column.
"""
def snap_to_widest(to_snap: list[list[object]], widests: list[int]) -> list[list[str]] {
    new_table = [];
    for row in to_snap {
        new_row = [f'{str(row[i]):{widests[i]}}' for i in range(len(widests))];
        new_table.append(new_row);
    }
    return new_table;
}