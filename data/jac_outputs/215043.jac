"""Reverse the order in a list."""
def reverseListOrder(query: list[object]) -> list[object] {
    list_query = list(query);
    list_query.reverse();
    return list_query;
}