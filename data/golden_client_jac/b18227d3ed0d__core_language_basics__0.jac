import from collections { Counter, defaultdict }

with entry {
    counts = Counter(["a", "b", "a", "c", "a"]);
    print(counts["a"]);  # 3
}
