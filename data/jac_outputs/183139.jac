"""
    VOTT header file version
    :param doc_name: Label.json
    :return: The header for the label.json file
    """
def get_label_file_template(doc_name: Any) -> object {
    return {"document": doc_name, "labels": []};
}