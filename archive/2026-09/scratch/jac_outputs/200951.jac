"""Returns true if the given object is a discord File object."""
def is_discord_file(`obj: object) -> bool {
    return `obj.__class__.__name__ == "File";
}