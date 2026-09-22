"""Parsing arguments in op_par_loop to find the correct closing brace"""
def arg_parse(text: Any, j: Any) -> object {
    depth = 0;
    loc2 = j;
    while 1 {
        if (text[loc2] == '(') {
            depth = depth + 1;
        } elif (text[loc2] == ')') {
            depth = depth - 1;
            if (depth == 0) {
                return loc2;
            }
        }
        loc2 = loc2 + 1;
    }
}