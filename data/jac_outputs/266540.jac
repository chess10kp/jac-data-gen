"""Split off the tagblock from the rest of the message.

Note that if the nmea is a concatenated multipart message then only the tagblock of
the first message will be split off."""
def split_tagblock(nmea: str) -> tuple[str, str] {
    tagblock = '';
    if nmea.startswith("\\") and not nmea.startswith("\\!") {
        (tagblock, nmea) = nmea[1:].split("\\", 1);
    }
    return (tagblock, nmea);
}