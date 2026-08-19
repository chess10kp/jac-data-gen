import from collections { Counter }

with entry {
    counts = Counter(["a", "b", "a", "c", "a"]);
    print(counts["a"]);  # 3
}
