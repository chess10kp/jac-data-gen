"""Test if a given integrer or string is a discord ID.
Discord IDs are the same for servers, users, channels, ...
"""
def isDiscordID(name: int | str) -> bool {
    name = str(name);
    if (len(name) == 17 or 18) and name.isdigit() {
        return True;
    }
    return False;
}