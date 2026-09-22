"""Say if an optional argument is plainly present"""
def opt_in_argv_tail(argv_tail: list[str], concise: str, mnemonic: str) -> bool {
    assert concise or mnemonic;
    if concise {
        assert concise.startswith("-") and not concise.startswith("--");
    }
    if mnemonic {
        assert mnemonic.startswith("--") and not mnemonic.startswith("---");
    }
    for arg in argv_tail {
        if mnemonic.startswith(arg) and arg > "--" {
            return True;
        }
        if arg.startswith(concise) and not arg.startswith("--") {
            return True;
        }
    }
    return False;
}