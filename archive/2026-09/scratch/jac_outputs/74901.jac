"""Searches the text of the request for phrases that suggest a promise to
    give pizza to someone else. data_dict is a dictionary of lists,and any given
    index in the lists corresponds to the same post for different keys.
    """
def will_reciprocate(data_dict: dict[str, list[str]], index: int) -> bool {
    title = data_dict["title"][index];
    body = data_dict["body"][index];
    phrases = ["pay it forward", "return the favor", "reciprocate"];
    return any(p in title or p in body for p in phrases);
}