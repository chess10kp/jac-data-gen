"""Returns the Player ID for the given player."""
def getPlayerID(playerOrID: Any) -> object {
    if ((playerOrID is None) or (playerOrID == -1)) {
        return -1;
    }
    if isinstance(playerOrID, int) {
        return playerOrID;
    }
    return playerOrID.getID();
}