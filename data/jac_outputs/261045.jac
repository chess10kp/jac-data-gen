"""Convert a Stack room name into an idiomatic IRC channel name by downcasing
and replacing whitespace with hyphens.
"""
def tochannel(room_name: str) -> str {
    return '#' + room_name.lower().replace(' ', '-');
}