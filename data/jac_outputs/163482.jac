"""aoc day6 part 1: Count the number of questions for which anyone answered 'yes'."""
def count_answers(text_input: list[str]) -> int {
    total = 0;
    target = 'abcdefghijklmnopqrstuvwxyz';
    for group in text_input {
        for char in target {
            if char in group {
                total += 1;
            }
        }
    }
    return total;
}