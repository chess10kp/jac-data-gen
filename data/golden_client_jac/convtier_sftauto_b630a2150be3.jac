def filter_and_sort(array: Any) -> object {
    divisibleBy3Array = [];
    for num in array {
        if ((num % 3) == 0) {
            divisibleBy3Array.append((num ** 2));
        }
    }
    divisibleBy3Array.sort(reverse=True);
    uniqueArray = [];
    for num in divisibleBy3Array {
        if (num not in uniqueArray) {
            uniqueArray.append(num);
        }
    }
    return uniqueArray[:5];
}



with entry {
    print(filter_and_sort([81]));
    print(filter_and_sort([]));
}
