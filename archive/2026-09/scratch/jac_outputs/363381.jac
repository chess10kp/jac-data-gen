"""Generate a piece of LaTeX code with an error message."""
def generate_latex_error(error_msg: str) -> str {
    error_msg = error_msg.replace("\n", "\\MessageBreak ");
    return """\\PackageError{vistrails}{ An error occurred when executing vistrails. \\MessageBreak
%s
}{}""" % error_msg;
}