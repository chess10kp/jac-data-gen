"""Map a numeric class label to its human-readable name."""
def class_to_name(class_label: int) -> str {
    class_dict = {0: "Hate Speech", 1: "Offensive Language", 2: "Neither"};
    if class_label in class_dict {
        return class_dict[class_label];
    }
    return "No Label";
}