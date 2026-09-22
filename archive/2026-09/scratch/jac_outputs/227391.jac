"""Check if own work by uploader."""
def OwnWork(pagetext: str) -> bool {
    lower_case_page_text = pagetext.lower();
    return '{{own}}' in lower_case_page_text or 'own work' in lower_case_page_text;
}