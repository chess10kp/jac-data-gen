def example(condition: bool, other_condition: bool) -> str {
    if condition {
        print("condition true");
    } elif other_condition {
        print("other condition");
    } else {
        print("else");
    }
    result = "yes" if condition else "no";
    return result;
}
