"""Takes a string context_type and makes that a standard 'label' string."""
def doc_label_name(context_type: str) -> str {
    str(context_type) + '_label'
}