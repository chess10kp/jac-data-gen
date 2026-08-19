def max_continuous_sum(arr: Any) -> object {
    if not arr {
        return 0;
    }
    inclusive = arr[0];
    exclusive = 0;
    for i in range(1, len(arr)) {
        new_inclusive = exclusive + arr[i];
        exclusive = max(inclusive, exclusive);
        inclusive = new_inclusive;
    }
    return max(inclusive, exclusive);
}



with entry {
    print(max_continuous_sum(0));
}
