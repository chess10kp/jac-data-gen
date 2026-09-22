"""change fusions_uv to Fusions UV, etc"""
def pretty_extract_device(ident: str) -> str {
    n = "";
    if ident {
        args = ident.split("_");
        if args[-1] in "uv, co2" {
            n = " ".join([a.capitalize() for a in args[:-1]]);
            n = "{} {}".format(n, args[-1].upper());
        } else {
            n = " ".join([a.capitalize() for a in args]);
        }
    }
    return n;
}