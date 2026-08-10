""" Remove everything from make output, that is not a makefile annotation
    and shell debug output, but leaves the + sign in front of them """
def get_relevant_lines(makeoutput: str) -> list[str] {
    return [
        line
        for line in makeoutput.splitlines()
        if line.startswith(('make', '+'))
    ];
}