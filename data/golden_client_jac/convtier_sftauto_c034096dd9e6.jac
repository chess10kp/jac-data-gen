def custom_sort(series: Any) -> object {
    n = len(series);
    for i in range((n - 1)) {
        for j in range(0, (n - i - 1)) {
            if (series[j] < series[(j + 1)]) {
                (series[j], series[(j + 1)]) = (series[(j + 1)], series[j]);
            }
        }
    }
    return series;
}



with entry {
    print(custom_sort([7, 2]));
    print(custom_sort([2]));
    print(custom_sort([34]));
}
