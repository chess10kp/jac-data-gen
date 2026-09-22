"""Heuristic bone name matching algorithm."""
def bonenamematch(name1: str, name2: str) -> bool {
    if name1 == name2 {
        return True;
    }
    if name1.startswith("Bip01 L ") {
        name1 = "Bip01 " + name1[8:] + ".L";
    } elif name1.startswith("Bip01 R ") {
        name1 = "Bip01 " + name1[8:] + ".R";
    }
    if name2.startswith("Bip01 L ") {
        name2 = "Bip01 " + name2[8:] + ".L";
    } elif name2.startswith("Bip01 R ") {
        name2 = "Bip01 " + name2[8:] + ".R";
    }
    return name1 == name2;
}