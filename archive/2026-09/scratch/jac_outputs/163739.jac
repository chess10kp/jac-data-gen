"""Converts a string formula into a series of tokens for evaluation."""
def _tokenize_string(formula: str) -> list[str] {
    assert isinstance(formula, str);
    token_list: list[str] = [];
    accumulated = "";
    for char in formula {
        if char in ["(", ")", "+", "^", " ", "[", "]", "=", "~"] {
            if accumulated != "" {
                token_list.append(accumulated);
            }
            token_list.append(char);
            accumulated = "";
        } elif char == "*" {
            if accumulated == "*" {
                token_list.append("^");
                accumulated = "";
            } elif accumulated != "" {
                token_list.append(accumulated);
                accumulated = "*";
            } else {
                accumulated = "*";
            }
        } else {
            if accumulated == "*" {
                token_list.append(accumulated);
                accumulated = "";
            }
            accumulated += char;
        }
    }
    if accumulated != "" {
        token_list.append(accumulated);
    }
    outlist: list[str] = [];
    for item in token_list {
        if item not in [" ", "[", "]"] {
            outlist.append(item);
        } elif item == "[" {
            outlist.append(outlist.pop() + item);
        } elif item == "]" {
            if len(outlist) < 2 {
                raise SyntaxError("error in using square brackets in formula input");
            }
            outlist.append(outlist.pop(-2) + outlist.pop() + item);
        }
    }
    if outlist[0] == "y" {
        outlist.pop(0);
    }
    if outlist[0] in ["=", "~"] {
        outlist.pop(0);
    }
    for item in outlist {
        if (not ("[" in item) and ("]" in item)) or (not ("]" in item) and ("[" in item)) {
            raise SyntaxError("cannot nest operators in square brackets in formula input");
        }
        if item == "call" {
            raise SyntaxError("'call' cannot be used as a variable name in formula input");
        }
        if item in ["=", "~"] {
            raise SyntaxError("LHS in formula is not correctly specified");
        }
    }
    return outlist;
}