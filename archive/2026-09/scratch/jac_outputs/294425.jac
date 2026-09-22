"""Opens the brackets, depending upon the Sign."""
def signExp(expression: str, sign: str) -> str {
    arr = list(expression);
    if sign == "-" {
        for (i, ch) in enumerate(arr) {
            if ch == "+" {
                arr[i] = "-";
            } elif ch == "-" {
                arr[i] = "+";
            }
        }
    }
    if arr[0] != "+" and arr[0] != "-" {
        arr.insert(0, sign);
    }
    return "".join(x for x in arr);
}