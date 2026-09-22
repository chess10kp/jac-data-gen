"""Compares the Zotero and Notion keys."""
def compareKeys(zotkeys: list[str], notkeys: list[str]) -> list[str] {
    return [zkey for zkey in zotkeys if zkey not in notkeys];
}