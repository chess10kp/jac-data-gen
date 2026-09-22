"""
Calculate the max needed length for a output col by getting the headline, the content of the rows
(different data types) and in some cases a specific key
"""
def col_length(headline: str, content: list[str] | dict[str, dict[str, str] | int | float] | int, dict_key: str | None = None) -> int {
    length = len(headline);
    if type(content) == list {
        for x in content {
            if type(x) == str {
                if len(x) > length {
                    length = len(x);
                }
            }
        }
    } elif type(content) == dict {
        for key in content {
            if type(content[key]) == dict {
                if dict_key in content[key] {
                    if len(str(content[key][dict_key])) > length {
                        length = len(str(content[key][dict_key]));
                    }
                } else {
                    x = key;
                    for key in content[x] {
                        if type(content[x][key]) == dict {
                            if dict_key in content[x][key] {
                                if type(content[x][key]) == dict {
                                    if len(content[x][key][dict_key]) > length {
                                        length = len(content[x][key][dict_key]);
                                    }
                                }
                            }
                        }
                    }
                }
            } elif type(content[key]) == int or type(content[key]) == float {
                if len(str(content[key])) > length {
                    length = len(str(content[key]));
                }
            }
        }
    } elif type(content) == int {
        if len(str(content)) > length {
            length = len(str(content));
        }
    }
    return length;
}