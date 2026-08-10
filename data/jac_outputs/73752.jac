""" We assume that if a value is None then k is a flag and should be appended with no value"""
def dict_to_opts(d: dict[str, str | list[str | int] | int | float | bool | None]) -> list[str] {
    opts = list();
    for (k, v) in d.items() {
        opts.append(f"--{k}");
        if type(v) is list {
            for sub_v in v {
                opts.append(str(sub_v));
            }
        } elif v is None {
            ;
        } else {
            opts.append(str(v));
        }
    }
    return opts;
}