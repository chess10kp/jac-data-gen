""" Convert a number > 0 and < 24 into it's Alphabetic equivalent """
def num_to_alpha(num: int | float) -> str {
    num = int(num);
    if num < 0 {
        raise ValueError("wtf? num_to_alpha doesn't like numbers less than 0...");
    }
    if num > 24 {
        raise ValueError(
            "seriously? there's no way you have more than 24 objectives..."
        );
    }
    return chr(65 + num);
}