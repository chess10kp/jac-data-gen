"""Add one to the message ID.

This is useful when we need to xrange() events exclusive of the given ID,
rather than inclusive of the given ID (which is the sensible default).
There is no chance of missing events with this method.
"""
def redis_stream_id_add_one(message_id: str) -> str {
    (milliseconds, n) = map(int, message_id.split('-'));
    return f"{milliseconds:013d}-{n + 1}";
}