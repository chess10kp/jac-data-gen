"""ORIGINAL_STR of type string, will return each word of string with the first letter of each word capitalized."""
def capitalizeEachWord(original_str: str) -> str {
    result = "";
    list_of_words = original_str.split();
    for elem in list_of_words {
        if len(result) > 0 {
            result = result + " " + elem.strip().capitalize();
        } else {
            result = elem.capitalize();
        }
    }
    if not result {
        return original_str;
    }
    return result;
}