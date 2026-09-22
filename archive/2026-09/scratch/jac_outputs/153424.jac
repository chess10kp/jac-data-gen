"""Return summ exons length."""
def get_bed_len(bed_line: str) -> int {
    block_sizes = [
        int(x)
        for x in bed_line.split("\t")[10].split(",")
        if x
    ];
    return sum(block_sizes);
}