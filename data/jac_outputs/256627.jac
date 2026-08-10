"""
Calculates the highest ID of all the updates it receive from getUpdates.
:param updates: getUpdates()
:return: last update id
"""
def get_last_update_id(updates: dict[str, list[dict[str, int]]]) -> int {
    return max(int(update["update_id"]) for update in updates["result"]);
}