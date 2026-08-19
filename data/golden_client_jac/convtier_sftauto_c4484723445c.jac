def sum_unique_integers(lst: Any) -> object {
    unique_numbers = `set();
    total_sum = 0;
    for num in lst {
        if (num not in unique_numbers) {
            unique_numbers.add(num);
            total_sum += num;
        }
    }
    return total_sum;
}



with entry {
    print(sum_unique_integers([81]));
    print(sum_unique_integers([]));
    print(sum_unique_integers([100]));
}
