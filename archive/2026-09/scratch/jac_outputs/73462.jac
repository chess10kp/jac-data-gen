"""https://minecraft-de.gamepedia.com/UUID"""
def is_valid_mojang_uuid(uuid: str) -> bool {
    allowed_chars = '0123456789abcdef';
    uuid = uuid.lower();
    if len(uuid) != 32 {
        return False;
    }
    return all(char in allowed_chars for char in uuid);
}