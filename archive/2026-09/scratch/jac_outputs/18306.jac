"""ersetzt alle Vorkommen von '<a href="xxxxxxxx" ... >yyyy</a>' durch '(xxxxxxxx : yyyy)' """
def links_as_text(code: str) -> str {
    def link_as_text(code: str) -> tuple[int, str] {
        ret = code;
        i = code.rfind('<a href="');
        if i > -1 {
            j = code.find('"', i + 9);
            k = code.find('>', j);
            l = code.find('<', k);
            ret = code[:i] + '(' + code[i + 9:j] + ' : ' + code[k + 1:l] + ')' + code[l + 4:];
        }
        return (i, ret);
    }
    i = 1;
    ret = code;
    while i > -1 {
        (i, ret) = link_as_text(ret);
    }
    return ret;
}