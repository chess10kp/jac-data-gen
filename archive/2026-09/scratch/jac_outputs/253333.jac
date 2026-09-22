"""
    Given a list of file names, return the article xml file name
    """
def article_xml_from_filename_map(filenames: Any) -> object {
    for file_name in filenames {
        if file_name.endswith(".xml") {
            return file_name;
        }
    }
    return None;
}