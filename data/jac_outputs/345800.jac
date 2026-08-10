"""Calculate the Gini index for a split dataset (0 is perfect split)."""
def gini_index(groups: list[list[int]], class_values: list[int]) -> float {
    gini = 0.0;
    for class_value in class_values {
        for group in groups {
            size = len(group);
            if size == 0 {
                continue;
            }
            proportion = [row[-1] for row in group].count(class_value) / float(size);
            gini += proportion * (1.0 - proportion);
        }
    }
    return gini;
}