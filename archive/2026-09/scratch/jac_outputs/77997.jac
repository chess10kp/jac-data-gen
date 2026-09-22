"""findDictInDictList."""
def findDictInDictList(dictList: list[dict[str, int | str]], value: int | str) -> dict[str, int | str] {
    dict_val = {};
    for row in dictList {
        if row['fileID'] == value {
            dict_val = row;
        }
    }
    return dict_val;
}