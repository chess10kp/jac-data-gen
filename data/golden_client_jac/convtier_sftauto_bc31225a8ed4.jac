def find_first_occurrence(numbers: Any) -> object {
    index = -1;
    for i in range(len(numbers)) {
        if (numbers[i] == 7) {
            index = i;
            break;
        }
    }
    if (index == -1) {
        return -1;
    } else {
        return index;
    }
}



with entry {
    print(find_first_occurrence('hello'));
}
