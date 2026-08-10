"""
Returns the unique values from the list containing no. of items
"""
def getUniqueValuesFromList(inlist: list[object]) -> list[object] {
    values = [];
    for feature in inlist {
        if feature not in values {
            values.append(feature);
        }
    }
    return values;
}