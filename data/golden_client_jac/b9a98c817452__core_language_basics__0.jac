def classify_number(n: int) -> str {
    if n < 0 {
        return "negative";
    } elif n == 0 {
        return "zero";
    } else {
        return "positive";
    }
}

with entry {
    print(classify_number(-5));  # negative
    print(classify_number(0));   # zero
    print(classify_number(10));  # positive
}
