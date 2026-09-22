"""Returns important range of time in which the celebrities enter the room
    params: Time {2D array containing entering and leaving time of each celebrity}"""
def preprocessing(Time: Any) -> object {
    impRange = Time.copy();
    impRange = `list(`set([a[0] for a in impRange]));
    impRange.sort();
    return impRange;
}