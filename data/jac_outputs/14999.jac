"""
    Composes the predicate with the morton ranges.
    """
def addMortonCondition(mortonRanges: Any, mortonColumnName: Any) -> object {
    elements = [];
    for mortonRange in mortonRanges {
        elements.append(
            (
                '('
                + mortonColumnName
                + ' between '
                + str(mortonRange[0])
                + ' and '
                + str(mortonRange[1])
                + ')'
            )
        );
    }
    if (len(elements) == 1) {
        return elements[0];
    } elif (len(elements) > 1) {
        return ('(' + ' OR '.join(elements) + ')');
    }
    return None;
}