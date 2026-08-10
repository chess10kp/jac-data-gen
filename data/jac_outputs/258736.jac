"""Serialize the tags we want to set for storage in the AGFI description."""
def firesim_tags_to_description(
    buildtriplet: str, deploytriplet: str, commit: str
) -> str {
    return f"firesim-buildtriplet:{buildtriplet},firesim-deploytriplet:{deploytriplet},firesim-commit:{commit}";
}