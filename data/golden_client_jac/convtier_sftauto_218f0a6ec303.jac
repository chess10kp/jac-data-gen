def divisible_by_7_and_5(lst: Any) -> object {
    if (len(lst) == 0) {
        return True;
    } else {
        return all((((num % 7) == 0) and ((num % 5) == 0)) for num in lst);
    }
}



with entry {
    print(divisible_by_7_and_5([]));
    print(divisible_by_7_and_5([6, -12]));
}
