"""Return non-XFormInstances (duplicates, errors, etc.)"""
def problem_forms(doc: dict[str, str]) -> bool {
    return doc["doc_type"] != "XFormInstance";
}