"""Replace tabs by spaces"""
def fix_indentation(text: str) -> str {
    return text.replace('\t', ' ' * 4);
}