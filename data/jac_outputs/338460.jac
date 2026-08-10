"""Return the string representation of the partition function."""
def write_partition_str(partitions: list[list[str | int]]) -> str {
    output = "let partition node = match node with\n";
    for (i, nodes) in enumerate(partitions) {
        output += "\n".join([f"  | {node}n -> {i}" for node in nodes]) + "\n";
    }
    return output;
}