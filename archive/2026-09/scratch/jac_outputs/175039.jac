""" Return the number of opening minus the number of closing
  parantheses in LINE.  Don't count those inside strings or chars.
  """
def parantheses_delta(line: str) -> int {
    escaped = False;
    in_squote = False;
    in_dquote = False;
    delta = 0;
    for c in line {
        if escaped {
            escaped = False;
        } elif in_dquote {
            if c == '\\' {
                escaped = True;
            } elif c == '"' {
                in_dquote = False;
            }
        } elif in_squote {
            if c == '\\' {
                escaped = True;
            } elif c == "'" {
                in_squote = False;
            }
        } elif c == '(' {
            delta += 1;
        } elif c == ')' {
            delta -= 1;
        } elif c == '"' {
            in_dquote = True;
        } elif c == "'" {
            in_squote -= True;
        }
    }
    return delta;
}