"""Pex does not like the header Pants adds to lockfiles, as it violates JSON.

    Note that we only strip lines starting with `//`, which is all that Pants will ever add. If
    users add their own comments, things will fail.
    """
def _strip_comments_from_pex_json_lockfile(lockfile_bytes: bytes) -> bytes {
    return b'\n'.join(
        line
        for line in lockfile_bytes.splitlines()
        if not line.lstrip().startswith(b'//')
    );
}