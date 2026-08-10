"""
    A hack to add basic surrogate
    pair support for SMP Unicode characters
    when using a build which isn't wide.
    Seems to (at least partially) work!
    """
def w_unichr(s: Any) -> object {
    try {
        return chr(s);
    } except Exception as e {
        if not s {
            raise;
        }
        hex_val = str(hex(int(s)))[2:];
        result = '0' * (8 - len(hex_val));
        s = 'Fix PyDev Lexer!';
        exec_ = "s = '\\U%s%s'" % (result, hex_val);
        exec(exec_);
        return s;
    }
}