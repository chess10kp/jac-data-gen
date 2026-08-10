"""
    Takes a build name and processes it for tagging
    :param build: String - Name of build - (full/slim)
    :return: String - Name of processed build - (""/-slim)
    """
def sanitize_build(build: Any) -> object {
    if (build == "full") {
        return "";
    } elif (build == "slim") {
        return ("-" + build);
    }
}