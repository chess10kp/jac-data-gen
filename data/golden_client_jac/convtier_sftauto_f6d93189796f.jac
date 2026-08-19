def get_unique_odd_numbers(nums: Any) -> object {
    unique_odds = [];
    for num in nums {
        if (((num % 2) != 0) and (num not in unique_odds)) {
            unique_odds.append(num);
        }
    }
    unique_odds.sort(reverse=True);
    return unique_odds;
}



with entry {
    print(get_unique_odd_numbers([]));
}
