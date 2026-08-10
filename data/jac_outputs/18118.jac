"""Generate aspcapStar URL for apStar file paths."""
def aspcapStar_url(location_id: int, file_: str, url_header: str | None = None) -> str {
    if url_header is None or url_header is "sas" {
        url_header = "https://data.sdss.org/sas/dr13/apogee"
            "/spectro/redux/r6/stars/l30e/l30e.2";
    }
    url_header = url_header.strip();
    file_ = file_.strip();
    try {
        url = "%s/%s/%s" % (url_header, location_id, file_);
    } except Exception {
        raise ValueError("@Cham: This is not an option!");
    }
    return url;
}