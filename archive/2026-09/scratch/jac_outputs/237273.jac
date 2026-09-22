"""
  Takes an arbitrary number of seriesLists and adds them to a single seriesList. This is used
  to pass multiple seriesLists to a function which only takes one
  """
def group(requestContext: dict[str, object], *seriesLists: list[object]) -> list[object] {
    seriesGroup = [];
    for s in seriesLists {
        seriesGroup.extend(s);
    }
    return seriesGroup;
}