"""
    Return a uid with all unacceptable characters replaced with underscores
    """
def clean_uid(uid: Any) -> object {
    if not hasattr(uid, 'replace') {
        return clean_uid(str(uid.astype('S')));
    }
    try {
        return uid.decode('utf-8').replace("/", "_").replace(":", "_");
    } except AttributeError {
        return uid.replace("/", "_").replace(":", "_");
    }
}