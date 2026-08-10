"""Build an argv list from a Microsoft shell style cmdline str."""
def cmdline2list(cmdline: str) -> list[str] {
    whitespace = ' \t';
    bs_count = 0;
    in_quotes = False;
    arg = [];
    argv = [];
    for ch in cmdline {
        if ch in whitespace and not in_quotes {
            if arg {
                argv.append(''.join(arg));
                arg = [];
            }
            bs_count = 0;
        } elif ch == '\\' {
            arg.append(ch);
            bs_count += 1;
        } elif ch == '"' {
            if not bs_count % 2 {
                if bs_count {
                    delete(arg[-(bs_count / 2):],);
                }
                in_quotes = not in_quotes;
            } else {
                delete(arg[-((bs_count / 2) + 1):],);
                arg.append(ch);
            }
            bs_count = 0;
        } else {
            arg.append(ch);
            bs_count = 0;
        }
    }
    if arg or in_quotes {
        argv.append(''.join(arg));
    }
    return argv;
}