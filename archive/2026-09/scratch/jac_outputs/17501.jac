"""
    converts metadata list-of-lists to caption string which is one antinode per line
"""
def caption_from_metadata(metadata: list[list[float]]) -> str {
    caption = "";
    for (an, row) in enumerate(metadata) {
        [cx, cy, a, b, angle, rings] = row;
        this_caption = "{0},{1},{2},{3},{4},{5}".format(cx, cy, a, b, angle, rings);
        if an > 0 {
            caption += "\n";
        }
        caption += this_caption;
    }
    return caption;
}