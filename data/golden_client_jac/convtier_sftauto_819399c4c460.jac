def find_entries(list_of_dicts: Any) -> object {
    result = [];
    for dictionary in list_of_dicts {
        if (
            (dictionary['Name'] == 'John')
            and (dictionary['Age'] > 25)
            and (dictionary['Height'] < 180)
        ) {
            result.append(dictionary);
        }
    }
    return result;
}



with entry {
    print(find_entries([]));
}
