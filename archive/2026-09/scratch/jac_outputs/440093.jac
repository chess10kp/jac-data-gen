"""Check if name is a Tarball."""
def is_tar(name: str) -> bool {
    return name.endswith((".tar", ".gz", ".bz2"));
}