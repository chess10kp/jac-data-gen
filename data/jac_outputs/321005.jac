"""
    # windows compatible
    Translate a sequence of arguments into a command line
    string, using the same rules as the MS C runtime:

    1) Arguments are delimited by white space, which is either a
       space or a tab.

    2) A string surrounded by double quotation marks is
       interpreted as a single argument, regardless of white space
       contained within.  A quoted string can be embedded in an
       argument.

    3) A double quotation mark preceded by a backslash is
       interpreted as a literal double quotation mark.

    4) Backslashes are interpreted literally, unless they
       immediately precede a double quotation mark.

    5) If backslashes immediately precede a double quotation mark,
       every pair of backslashes is interpreted as a literal
       backslash.  If the number of backslashes is odd, the last
       backslash escapes the next double quotation mark as
       described in rule 3.
    """
def list2cmdline_patch(seq: list[str | bytes]) -> str {
    result = [];
    for raw_arg in seq {
        bs_buf = [];
        if result {
            result.append(' ');
        }
        if isinstance(raw_arg, bytes) {
            try {
                arg = raw_arg.decode();
            } except UnicodeDecodeError {
                print('debug:');
                print(raw_arg);
                arg = raw_arg.replace(b'\xa0', b'\xc2\xa0').decode();
            }
        } else {
            arg = raw_arg;
        }
        needquote = " " in arg or "\t" in arg or not arg;
        if needquote {
            result.append('"');
        }
        for c in arg {
            if c == '\\' {
                bs_buf.append(c);
            } elif c == '"' {
                result.append('\\' * len(bs_buf) * 2);
                bs_buf = [];
                result.append('\\"');
            } else {
                if bs_buf {
                    result.extend(bs_buf);
                    bs_buf = [];
                }
                result.append(c);
            }
        }
        if bs_buf {
            result.extend(bs_buf);
        }
        if needquote {
            result.extend(bs_buf);
            result.append('"');
        }
    }
    return ''.join(result);
}