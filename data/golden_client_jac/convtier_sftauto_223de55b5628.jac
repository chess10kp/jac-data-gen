def round_array(arr: Any) -> object {
    rounded_array = [];
    for num in arr {
        rounded_num = int(num);
        if ((num - rounded_num) > 0.5) {
            rounded_num += 1;
        }
        rounded_array.append(rounded_num);
    }
    return rounded_array;
}



with entry {
    print(round_array([]));
}
