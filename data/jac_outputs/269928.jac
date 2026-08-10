"""Helper method to extract channel ID from a Backplane scope."""
def channel_from_scope(scope: Any) -> object {
    idx = scope.find('channel');
    return scope[(idx + 8):];
}