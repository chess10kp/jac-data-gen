def reverse_weekdays(weekdays: Any) -> object {
    weekdays.sort(reverse=True);
    return weekdays;
}



with entry {
    print(reverse_weekdays([81]));
    print(reverse_weekdays([]));
    print(reverse_weekdays(['a']));
}
