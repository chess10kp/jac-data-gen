"""Function to return formatted URL given category, page number, date."""
def pageurl_template(category: str, pagenum: int, date: int | str) -> str {
    assert len(str(date)) == 8, 'Invalid input date format';
    return f"https://news.daum.net/breakingnews/{category}?page={pagenum}&regDate={date}";
}