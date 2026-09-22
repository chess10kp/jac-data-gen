"""
    Parses the fullData set and returns only those servers with "hive" in their name.
    This could probably be generalized to return other machines like those in Soda.
    """
def onlyHive(fullData: Any) -> object {
    toReturn = {};
    for server in fullData {
        if (str(server)[0:4] == "hive") {
            toReturn[server] = fullData[server];
        }
    }
    return toReturn;
}