"""retourne l'id du salon"""
def getNumChannel(name: str) -> int {
    index = name.find("_");
    numRaid = int(name[:index]);
    return numRaid;
}