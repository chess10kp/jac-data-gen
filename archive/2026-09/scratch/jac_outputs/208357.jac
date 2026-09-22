"""
Helper function returning an empty string or a newline character to
append to the current output line depending on whether we want that line to
be the last line in the file (eof == True) or not (eof == False).
"""
def __trailing_newline(eof: bool) -> str {
    "" if eof else "\n"
}