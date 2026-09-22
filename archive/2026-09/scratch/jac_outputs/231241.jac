"""
  Parses an S-Expression into a list-based tree.

  parse_sexp("(+ 5 (+ 3 5))") results in [['+', '5', ['+', '3', '5']]]
  """
def parse_sexp(string: str) -> list[str | list] {
    sexp = [[]];
    word = '';
    in_str = False;
    for c in string {
        if c == '(' and not in_str {
            sexp.append([]);
        } elif c == ')' and not in_str {
            if word {
                sexp[-1].append(word);
                word = '';
            }
            temp = sexp.pop();
            sexp[-1].append(temp);
        } elif c in (' ', '\n', '\t') and not in_str {
            if word != '' {
                sexp[-1].append(word);
                word = '';
            }
        } elif c == '\"' {
            in_str = not in_str;
        } else {
            word += c;
        }
    }
    return sexp[0];
}