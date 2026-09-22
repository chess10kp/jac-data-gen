"""Takes an integer representing a set of permissions and returns a list
    of corresponding permission names."""
def get_permission_names(perm_int: int) -> list[str] {
    pms = {'God': 16, 'Admin': 8, 'Builder': 2, 'Player': 1, 'DM': 4};
    return [key for (key, value) in pms.items() if perm_int & value];
}