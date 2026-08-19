def assign_zero(data: Any) -> object {
    if isinstance(data, `list) {
        for i in range(len(data)) {
            data[i] = assign_zero(data[i]);
        }
        return data;
    } elif isinstance(data, `dict) {
        for key in data {
            data[key] = assign_zero(data[key]);
        }
        return data;
    } elif ((data == '') or (data != data)) {
        return 0;
    } else {
        return data;
    }
}



with entry {
    print(assign_zero('hello'));
    print(assign_zero('Racecar'));
    print(assign_zero('abcabc'));
}
