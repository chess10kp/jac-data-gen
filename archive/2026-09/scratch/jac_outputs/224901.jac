"""
The mathematical formula to calculate the number of permutations is n^r where n is the number of options.
In this case we have (0-9) giving us 10 options, and r = the permutations, the count of unknown numbers.
"""
def generateReplNumsList(count_of_unknown_numbers: int) -> list[str] {
    unk_nums = count_of_unknown_numbers;
    count = 10 ** unk_nums;
    my_list = list();
    for i in range(count) {
        n = str(i);
        if len(n) < unk_nums {
            padding = int(unk_nums - len(n));
            n = n.zfill(padding + 1);
        }
        my_list.append(n);
    }
    return my_list;
}