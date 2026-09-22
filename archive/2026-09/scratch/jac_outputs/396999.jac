"""Append food names from labels for nutrition analysis."""
def append_food_name(food_dict: dict[str, list], class_names: list[str]) -> dict[str, list] {
    food_labels = food_dict['labels'];
    food_names = [' '.join(class_names[int(i)].split('-')) for i in food_labels];
    food_dict['names'] = food_names;
    food_dict
}