def normalize_tags(words: list) -> list {
    cleaned = [w.lower().rstrip(".,!?;:") for w in words];
    tags = [];
    for w in cleaned {
        if w and w not in tags {
            tags.append(w);
        }
    }
    return tags;
}

with entry {
    print(normalize_tags(['Jac!', 'jac', 'ML.', '', 'Studio']));
}
