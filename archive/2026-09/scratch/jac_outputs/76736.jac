"""
When each character is read from the input, this function is sounded until it reaches the reflect board.
This function specifies that at each step I have to go through the index of each page
of the routers to reach the reflect board.
"""
def step_forward(
    position: int,
    panel_r: list[str],
    panel_l: list[str],
    connection_map: dict[str, str]
) -> int {
    return panel_l.index(connection_map[panel_r[position]]);
}