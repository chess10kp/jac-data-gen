"""Returns whether a cell is a Markdown cell"""
def is_markdown_cell(cell: dict[str, str]) -> bool {
    return cell["cell_type"] == "markdown";
}