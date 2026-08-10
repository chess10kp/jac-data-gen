"""check if accelrator &x is the same in both strings"""
def check_accelerator(msgid: str, msgstr: str, line_warns: list[str]) -> int {
    msgid = msgid.lower();
    msgstr = msgstr.lower();
    p1 = msgid.find('&');
    if p1 >= 0 {
        a1 = msgid[p1:(p1 + 2)];
        p2 = msgstr.find('&');
        if p2 < 0 and len(a1) > 1 {
            if a1[-1] in msgstr {
                line_warns.append('acc1');
                return 1;
            }
        } else {
            a2 = msgstr[p2:(p2 + 2)];
            if a1 != a2 {
                return 0;
            }
        }
    }
    return 0;
}