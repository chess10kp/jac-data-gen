"""Returns the key that may be used to sort benchmarks by label."""
def benchmark_sort_key(benchmark: dict[str, str]) -> str {
    if "label" not in benchmark {
        return "";
    }
    return benchmark["label"];
}