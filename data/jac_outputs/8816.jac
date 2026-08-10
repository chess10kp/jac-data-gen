"""
Given the genotype (ie the junction that was chosen), returns the corresponding insert
"""
def insert(rcd: str, insert_at_junctions: list[str], genotype: str) -> str {
    junctions = ["x", "y", "z"];
    if genotype[1] != "-" {
        j = junctions.index(genotype[1]);
        return insert_at_junctions[j];
    }
    return "-";
}