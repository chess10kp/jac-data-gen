"""Comparison function for use with builtin 'sorted'. Sorts the server serverId
   in numeric order."""
def compare_server_id(x: dict[str, str], y: dict[str, str]) -> int {
    ccard_x = int(x["serverId"].split("/")[0]);
    ccard_y = int(y["serverId"].split("/")[0]);
    return ccard_x - ccard_y;
}