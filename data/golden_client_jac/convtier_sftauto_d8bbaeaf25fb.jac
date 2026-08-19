def calculate_average(scores: Any) -> object {
    total = 0;
    for score in scores {
        total += score;
    }
    average = round((total / len(scores)));
    return average;
}



with entry {
    print(calculate_average([1296, -10368]));
    print(calculate_average([882, -126, -1296, -10368]));
}
