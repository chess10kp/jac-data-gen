def increase_and_multiply(tuples: Any) -> object {
    result = [];
    for tup in tuples {
        value_sum = sum(tup);
        if ((value_sum % 2) == 0) {
            result.append(((tup[0] + 1), (tup[1] + 1)));
        } else {
            result.append(((tup[0] * 2), (tup[1] * 2)));
        }
    }
    return result;
}



with entry {
    print(increase_and_multiply([]));
}
