"""
        A check line may contain more than 1 check.
        Here we get only the info(line aka string) from the 2nd check.
    """
def get_2nd_ck_line_from_line(line: Any) -> object {
    splited = line.split();
    ck2 = splited[4:];
    ck2 = ' '.join(ck2);
    return ck2;
}