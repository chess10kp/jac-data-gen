"""
    Converts odml style tuples to a parsable string representation.
    Every tuple is represented by brackets '()'. The individual elements of a tuple are
    separated by a semicolon ';'. The individual tuples are separated by a comma ','.
    An odml 3-tuple list of 2 tuples would be serialized to: "[(11;12;13),(21;22;23)]".
    """
def odml_tuple_export(odml_tuples: list[list[str]]) -> str {
    str_tuples = "";
    for val in odml_tuples {
        str_val = ";".join(val);
        if str_tuples {
            str_tuples = "%s,(%s)" % (str_tuples, str_val);
        } else {
            str_tuples = "(%s)" % str_val;
        }
    }
    return "[%s]" % str_tuples;
}