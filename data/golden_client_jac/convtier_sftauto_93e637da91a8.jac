def sum_of_cubes(arr: Any) -> object {
    sum_cubes = 0;
    for num in arr {
        try {
            sum_cubes += num ** 3;
        } except Exception {
            return None;
        }
    }
    return round(sum_cubes);
}



with entry {
    print(sum_of_cubes([81]));
    print(sum_of_cubes([]));
    print(sum_of_cubes([100]));
}
