"""Select the thumbail of a YouTube video"""
def select_thumbnail(snippet: dict[str, dict[str, dict[str, dict[str, int | str]]]]) -> str {
    thumbnails = sorted(
        snippet["snippet"]["thumbnails"].values(),
        key=lambda (x: dict[str, int | str]) { -int(x["width"]); }
    );
    for thumbnail in thumbnails {
        if float(thumbnail["width"]) / float(thumbnail["height"]) == 16.0 / 9 {
            return str(thumbnail["url"]);
        }
    }
    return "";
}