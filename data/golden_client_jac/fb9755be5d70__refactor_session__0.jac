obj Classifier {
    def describe(value: int) -> str {
        match value {
            case 0:
                return "zero";
            case 1 | 2 | 3:
                return "small";
            case _:
                return "medium";
        }
    }
}

with entry {
    c = Classifier();
    print(c.describe(0));
    print(c.describe(2));
    print(c.describe(50));
}
