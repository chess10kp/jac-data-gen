"""routine to filter elements corresponding to a comment/reply"""
def getFilteredDivs(divs: Any) -> object {
    filtered = `list();
    for div in divs {
        if (len(div.get("class")) == 1) {
            filtered.append(div);
        }
    }
    return filtered;
}