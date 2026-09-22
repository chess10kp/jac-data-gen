""" Takes a tweet url and returns its id """
def url_to_id(url: Any) -> object {
    character_list = url.split('/');
    return int(character_list[5]);
}