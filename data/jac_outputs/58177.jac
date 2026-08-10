type Text = str;

"""Return a list of delimiter locations in the str"""
def find_delimiter_loc(delimiter: str, str: Text) -> list[int] {
    return [i for i in range(len(str)) if str[i] == "%"];
}