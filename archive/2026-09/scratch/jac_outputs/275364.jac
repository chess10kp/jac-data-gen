"""Return the list of external links from page text."""
import re;

def get_links(page_text: str) -> list[str] {
    ragex = re.compile(r'\[\[.*?\]\]');
    matches = ragex.findall(page_text);
    return [s[2:-2].split("|")[0] for s in matches];
}