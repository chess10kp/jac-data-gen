"""Handle cases where X is under a "macrolanguage" on Wiktionary.

So far, only the Chinese languages necessitate this helper function.
We'll keep this function as simple as possible, until it becomes too
complicated and requires refactoring.
"""
def _language_name_for_scraping(language: str) -> str {
    return "Chinese" if language == "Cantonese" else language;
}