def remove_redundant(group: list[list[int]]) -> list[list[int]] {
    new_group = [];
    for j in group {
        new = [];
        for i in j {
            if i not in new {
                new.append(i);
            }
        }
        new_group.append(new);
    }
    return new_group;
}