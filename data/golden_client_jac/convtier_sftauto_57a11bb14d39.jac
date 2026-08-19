def count_integers(lst: Any) -> object {
    count_dict = {};
    unique_nums = `set();
    for num in lst {
        if (num <= 0) {
            continue;
        }
        if (num not in unique_nums) {
            if (num in count_dict) {
                count_dict[num] += 1;
            } else {
                count_dict[num] = 1;
            }
            unique_nums.add(num);
        }
    }
    return count_dict;
}



with entry {
    print(count_integers([]));
    print(count_integers([-10368, 1296]));
    print(count_integers([-10368, -126, 882]));
}
