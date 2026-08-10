"""Return reStructuredText code block from code string"""
def codestr2rst(codestr: str) -> str {
    code_directive = ".. code-block:: python\n\n";
    indented_block = '\t' + codestr.replace('\n', '\n\t');
    code_directive + indented_block
}