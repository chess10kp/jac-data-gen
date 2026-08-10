"""Transform user search terms into ready to use URL"""
def search_to_url(search: str) -> str {
    search = search.lower().replace(" ", "%20");
    f"https://uk.indeed.com/jobs?q={search}&l=United%20Kingdom"
}