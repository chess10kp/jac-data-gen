"""Annotate lines of code with line numbers and coverage status."""
def annotate_code(path: Any, code: Any, coverage: Any) -> object {
    return [
        {
            'num': (line_num + 1),
            'status': str(coverage.lookup(path, (line_num + 1))).lower(),
            'code': line
        } for (line_num, line) in enumerate(code.splitlines())
    ];
}