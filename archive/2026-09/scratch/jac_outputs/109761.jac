"""Returns a database-ready string that contains the position in the form x/y"""
def _format_pos_to_db(pos: list[int]) -> str {
    return "{}/{}".format(pos[0], pos[1]);
}