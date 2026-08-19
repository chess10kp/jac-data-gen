def categorize(fruit: str) -> str {
    switch fruit {
        case "apple":
            return "pome";
        case "banana" | "plantain":
            return "berry";
        default:
            return "unknown";
    }
}
