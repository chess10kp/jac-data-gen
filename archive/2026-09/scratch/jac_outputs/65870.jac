"""Returns a list of tuples: [(screen_name, location), ...]
from json data (.json object)."""
def make_friends_list(json_data: dict[str, object]) -> list[tuple[str, str]] {
    friends = [];
    for friend in json_data['users'] as list[dict[str, object]] {
        location = friend['location'] as str;
        if location != '' {
            friends.append((friend['screen_name'] as str, location));
        }
    }
    return friends;
}