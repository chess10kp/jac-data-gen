"""calculate mean of numeric list"""
def mean(`list: Any) -> object {
    total = 0;
    for item in `list {
        total += item;
    }
    mean = total / len(`list);
    return mean;
}