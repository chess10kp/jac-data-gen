"""Remove unnecessary dots and commas from namelist value and use only one type of quotation marks."""
def mod_namelist_val(val: str) -> str | int | float {
    val = val.replace('"', "'");
    if val[-1] == "," {
        val = val[:-1];
    }
    if val[-1] == "." {
        val = val[:-1];
    }
    try {
        num = float(val);
        if num == int(num) {
            return int(num);
        }
        return num;
    } except ValueError {
        ;
    }
    return val;
}