"""Transform a game path relative to an extension root into a game path
relative to the game root."""
def get_path_in_ext(path: str, ext_name: str) -> str {
    if ext_name {
        return "/extensions/{}/{}".format(ext_name, path);
    }
    return path;
}