"""Return the db key for subscriber event data."""
def data(object_type: str, subscriber: str) -> str {
    return 'events:{}:{}:data'.format(object_type, subscriber);
}