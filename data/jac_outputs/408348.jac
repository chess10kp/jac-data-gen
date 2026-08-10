"""find which quote is the outer one, ' or "."""
def get_quote_style(str: Any) -> object {
    quote_char = None;
    at = None;
    found = str.find("'");
    found2 = str.find('"');
    if (found != found2) {
        if ((found >= 0) and (found2 >= 0)) {
            if (found < found2) {
                found2 = -1;
            } else {
                found = -1;
            }
        }
        if (found >= 0) {
            at = found + 1;
            quote_char = "'";
        } elif (found2 >= 0) {
            at = found2 + 1;
            quote_char = '"';
        }
    }
    return (quote_char, at);
}