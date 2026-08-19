def listItems(nums: Any) -> object {
    return [str((num * 2)) for num in nums];
}



with entry {
    print(listItems('hello'));
    print(listItems('Racecar'));
    print(listItems('abcabc'));
}
