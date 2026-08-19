def categorize(fruit: str) -> str {
    # Normalize so "Apple", " apple " and "apple" all match
    f = fruit.strip().lower();
    switch f {
        case "apple" | "pear":
            return "pome";
        case "banana" | "plantain":
            return "berry";
        case "carrot" | "potato":
            return "root vegetable";
        case "spinach" | "kale":
            return "leafy green";
        default:
            return "unknown";
    }
}
