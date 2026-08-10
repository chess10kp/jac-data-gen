"""Eats a list of items, groups consecutive items in separate lists and
        returns a list of lists."""
def build_ranges(page_list: list[int | str]) -> str {
    page_list.append(-1);
    output = [];
    last = int(page_list[0]) - 1;
    beginning = int(page_list[0]);
    for i in page_list {
        i = int(i);
        if i != last + 1 {
            output.append([str(beginning), str(last)]);
            beginning = i;
        }
        last = i;
    }
    page_list.pop();
    return ",".join(["-".join(x) for x in output]);
}