def listItems(input_list: Any) -> object {
    output_list = [];
    for num in input_list {
        multiplied_num = num * 2;
        if ((num % 3) == 0) {
            multiplied_num = str(multiplied_num) + "!";
        }
        output_list.append(str(multiplied_num));
    }
    output_list.sort(reverse=True);
    return output_list;
}



with entry {
    print(listItems([81]));
    print(listItems([]));
    print(listItems([100]));
}
