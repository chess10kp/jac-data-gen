""" Returns largest number """
def max(*numbers: int | float) -> int | float | None {
    if len(numbers) == 0 {
        return None;
    }
    maxnum = numbers[0];
    for n in numbers[1:] {
        if n > maxnum {
            maxnum = n;
        }
    }
    return maxnum;
}