"""
Converts a string to a list with more flexibility than string.split()
by looking for both brackets of type (,),[,],{,} and commas.
"""
def strtolist(string: str) -> list[int | float] {
    out: list[int | float] = [];
    temp = '';
    brackets = ['(', ')', '[', ']', '{', '}'];
    for char in list(string) {
        if char not in brackets and char != ',' {
            temp += char;
        }
        if char == ',' {
            try {
                out.append(int(temp));
            } except ValueError {
                out.append(float(temp));
            }
            temp = '';
        }
    }
    if len(temp) != 0 {
        try {
            out.append(int(temp));
        } except ValueError {
            out.append(float(temp));
        }
    }
    return out;
}