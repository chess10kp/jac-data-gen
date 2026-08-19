def generate_subsets(elements: Any) -> object {
    subsets = [[]];
    elements.sort();
    for element in elements {
        new_subsets = [];
        for subset in subsets {
            new_subset = subset + [element];
            new_subsets.append(new_subset);
        }
        subsets += new_subsets;
    }
    return subsets;
}



with entry {
    print(generate_subsets([]));
}
