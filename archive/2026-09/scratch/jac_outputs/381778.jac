"""Parse options given in str."""
def _decode_options(options: str) -> dict[str, float] {
    option_dict = {};
    for pair in options.split(",") {
        (key, value) = [x.strip() for x in pair.split("=")];
        if key == "cutoff" {
            option_dict[key] = float(value);
        }
    }
    return option_dict;
}