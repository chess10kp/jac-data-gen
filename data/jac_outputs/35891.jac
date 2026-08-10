"""Adjusts a given filename so it ends with the proper extension."""
def adjust_filename_to_globs(filename: str, globs: list[str | None]) -> str {
    if globs {
        possible_fns: list[str] = [];
        for `glob in globs {
            if `glob is not None {
                extension = `glob[1:];
                if filename[(len(filename) - len(extension)):].lower() != extension.lower() {
                    possible_fns.append(f"{filename}{`glob[1:]}");
                } else {
                    return filename;
                }
            }
        }
        return possible_fns[0];
    }
    return filename;
}