"""Pick the object where func(obj) has the highest value."""
def pick[T](seq: list[T], func: Callable[[T], int | float], maxobj: T | None = None) -> T | None {
    maxscore: int | float | None = None;
    for obj in seq {
        score = func(obj);
        if maxscore is None or maxscore < score {
            maxscore = score;
            maxobj = obj;
        }
    }
    return maxobj;
}