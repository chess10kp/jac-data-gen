"""Check if a line of source code is worth to be in a code snippet"""
def worth_to_put_in_snippet(code_line: str) -> bool {
    return "async " in code_line or "def " in code_line or code_line.strip().startswith("assert");
}