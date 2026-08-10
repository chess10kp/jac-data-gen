""" Explination: https://image.eveonline.com/ """
def icon_url(path: str, pk: int, size: int) -> str {
    filetype = "jpg" if path == "Character" else "png";
    return "http://image.eveonline.com/%s/%d_%d.%s" % (path, pk, size, filetype);
}