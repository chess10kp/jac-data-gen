"""Checks if the building type is a house, or if the item is being bought or sold."""
def checkBuildingType(line: str) -> str {
    if " is buying " in line {
        return "buy";
    } elif " is selling " in line {
        return "sell";
    } else {
        return "house";
    }
}