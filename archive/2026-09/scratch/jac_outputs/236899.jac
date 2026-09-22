"""Summary

    Args:
        entry_text (str): Journal text entry
        entry (dict): DayOne entry dict

    Returns:
        TYPE: journal text entry with inserted image links
    """
def link_photos(entry_text: str, `entry: dict[str, list[dict[str, str]]]) -> str {
    if "photos" not in `entry {
        return entry_text;
    }
    photo_list = [
        "{{" + "photos/{}.{}".format(photo["md5"], photo["type"]) + "}}"
        for photo in `entry["photos"]
    ];
    return entry_text + "\n\n" + "\n".join(photo_list);
}