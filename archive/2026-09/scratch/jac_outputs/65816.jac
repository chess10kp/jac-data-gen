"""
   The assumption is that the symbolic algebra optimization will always break
   out the function evaluation. Therefore there always is a line where the
   functional value is assigned to a variable. The actual functional
   subroutine call, at the latest, has to happen on the line before.
   This routine returns the line where the variable first appears.
   """
def find_subroutine_call_insertion_point(
    lines: Any, ifbranch: Any, varname: Any
) -> object {
    (lineno_start, lineno_end) = ifbranch;
    line = lineno_start;
    insert_point = -1;
    while (line <= lineno_end) {
        aline = lines[line];
        aline = aline.split(" = ");
        key = aline[0].lstrip();
        if (key == varname) {
            insert_point = line;
            break;
        }
        line += 1;
    }
    return insert_point;
}