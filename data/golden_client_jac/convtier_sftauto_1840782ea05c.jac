def find_highest_peak(elevations: Any) -> object {
    highest_peak = elevations[0];
    highest_peak_index = 0;
    for i in range(1, len(elevations)) {
        if (elevations[i] >= highest_peak) {
            highest_peak = elevations[i];
            highest_peak_index = i;
        }
    }
    return highest_peak_index;
}



with entry {
    print(find_highest_peak('hello'));
    print(find_highest_peak('Racecar'));
    print(find_highest_peak('abcabc'));
}
