"""
Split the command line into individual tokens.

we'd like to use shlex.split() but that doesn't work well for
windows types of things.  for now we'll take the easy approach
and just split on space. We'll then cycle through and look for leading
quotes and join those lines
"""
def split_cli(line: str) -> list[str] {
    parts = line.split(' ');
    final = [];
    while len(parts) > 0 {
        tok = parts.pop(0);
        if tok[:1] == '"' {
            tok = tok[1:];
            next = parts.pop(0);
            while next[-1:] != '"' and len(parts) > 0 {
                tok += ' ' + next;
                next = parts.pop(0);
            }
            if next[-1:] == '"' {
                tok += ' ' + next[:-1];
            }
        }
        final.append(tok);
    }
    return final;
}