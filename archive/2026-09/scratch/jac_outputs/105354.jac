glob PAGE_SIZE = 20;

"""Get nth page of a data, with each page having 20 entries."""
def get_page(data: list[object], page: int) -> list[object] {
    begin = page * PAGE_SIZE;
    end = page * PAGE_SIZE + PAGE_SIZE;
    if begin >= len(data) {
        return [];
    } elif end >= len(data) {
        return data[begin:];
    }
    return data[begin:end];
}