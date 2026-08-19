def find_second_highest(numbers: Any) -> object {
    if (len(numbers) < 2) {
        return None;
    }
    unique_numbers = sorted(`set(numbers), reverse=True);
    second_highest = unique_numbers[1]
        if (len(unique_numbers) >= 2)
        else unique_numbers[0];
    if (numbers.count(second_highest) > 1) {
        return find_second_highest(numbers[numbers.count(second_highest):]);
    } else {
        return second_highest;
    }
}



with entry {
    print(find_second_highest('Racecar'));
    print(find_second_highest([-8, -4, 2]));
    print(find_second_highest([-2, -1, 4, 7]));
}
