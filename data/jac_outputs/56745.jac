"""Check whether a filename has an allowable extension."""
def allowed_file(filename: str, extensions: set[str] = {'csv'}) -> bool {
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in extensions;
}