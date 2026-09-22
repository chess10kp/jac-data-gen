"""
    Parse the GID given and return a tuple with the following values:

    - The real GID without bitwise flags.
    - Whether or not the tile is horizontally flipped.
    - Whether or not the tile is vertically flipped.
    - Whether or not the tile is "diagonally" flipped.

    This is a low-level function used internally by this library; you
    don't typically need to use it.
    """
def t_gid_parse(gid: Any) -> object {
    rgid = gid - (gid & (1 << 31)) - (gid & (1 << 30)) - (gid & (1 << 29));
    hflip = bool((gid & (1 << 31)));
    vflip = bool((gid & (1 << 30)));
    dflip = bool((gid & (1 << 29)));
    return (rgid, hflip, vflip, dflip);
}