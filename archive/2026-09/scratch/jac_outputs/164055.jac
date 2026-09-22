def fix_number_value(query_toks: list[str], query_toks_no_value: list[str]) -> list[str] {
    def split_and_keep(s: str, sep: str) -> list[str] {
        if not s {
            return [""];
        }
        p = chr(ord(max(s)) + 1);
        return s.replace(sep, p + sep + p).split(p);
    }
    temp = [];
    for q in query_toks {
        temp += split_and_keep(q, ".");
    }
    query_toks = temp;
    (i_val, i_no_val) = (0, 0);
    while i_val < len(query_toks) and i_no_val < len(query_toks_no_value) {
        if query_toks_no_value[i_no_val] != "value" {
            i_val += 1;
            i_no_val += 1;
            continue;
        }
        i_val_end = i_val;
        while (i_val + 1) < len(query_toks) and (i_no_val + 1) < len(query_toks_no_value) and query_toks[i_val_end + 1].lower() != query_toks_no_value[i_no_val + 1].lower() {
            i_val_end += 1;
        }
        if i_val == i_val_end and query_toks[i_val] in ["1", "2", "3", "4", "5"] and query_toks[i_val - 1].lower() == "limit" {
            query_toks_no_value[i_no_val] = query_toks[i_val];
        }
        i_val = i_val_end;
        i_val += 1;
        i_no_val += 1;
    }
    return query_toks_no_value;
}