glob INVALID_NAME_CHARS = [':', '#', '<', '>', '$', '+', '!', '`', '&', "'", '"', '|', '*', '/', '\\', '@', '=', '{', '}', '?', '%'];

"""To remove the list of characters invalid in name of file"""
def handle_name(name: str) -> str {
    for ch in INVALID_NAME_CHARS {
        name = name.replace(ch, '');
    }
    return name;
}