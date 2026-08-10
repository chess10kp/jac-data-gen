"""Function to implement aggregate functions."""
def aggregate_function(a: dict[str, int | list[int]], b: int, func: str) -> bool {
    return_val = False;
    if func == "max" {
        a[func] = max(a[func], b);
    } elif func == "min" {
        a[func] = min(a[func], b);
    } elif func == "sum" {
        a[func] = a[func] + b;
    } elif func == "avg" {
        a[func][0] = a[func][0] + b;
        a[func][1] = a[func][1] + 1;
    } else {
        return_val = True;
    }
    return return_val;
}