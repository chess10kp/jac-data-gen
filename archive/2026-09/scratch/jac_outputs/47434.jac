"""Transforms two lists values into a list of couple of values"""
def create_points_list[T](lists: list[list[T]]) -> list[list[T]] {
    created: list[list[T]] = [];
    for i in range(len(lists[0])) {
        point: list[T] = [];
        for l in lists {
            point.append(l[i]);
        }
        created.append(point);
    }
    return created;
}