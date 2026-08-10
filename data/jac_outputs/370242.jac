"""generates the all section"""
def generate_section(inputfiles: list[str], align_sizes: list[int | None]) -> list[str] {
    cmd = ["tmp.all"];
    for (index, file) in enumerate(inputfiles) {
        cmd += [file];
        if align_sizes != [None] {
            cmd += ["--sectionalign", align_sizes[index + 1]];
        }
    }
    return cmd;
}