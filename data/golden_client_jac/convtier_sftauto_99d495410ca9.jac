def findNumberSum(numbers: Any) -> object {
    total = 0;
    for n in numbers {
        total += n;
    }
    return total;
}



with entry {
    print(findNumberSum([]));
}
