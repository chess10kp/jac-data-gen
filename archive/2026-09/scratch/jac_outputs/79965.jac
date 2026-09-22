"""
    Args:
        list of strings
    Output:
        list of strings without repeated words ('no more more please' -> 'no
        more please')
    """
def deldoubleword(data: Any) -> object {
    data = [x.split() for x in data];
    datalist = [];
    for sen in data {
        sen2 = [];
        for i in range(len(sen)) {
            if (sen[(i - 1)] != sen[i]) {
                sen2.append(sen[i]);
            }
        }
        senstring = ''.join((x + ' ') for x in sen2).rstrip();
        datalist.append(senstring);
    }
    return datalist;
}