"""
Does tag span many groups? If so we'll create pseudo group of groups.

Return the number of groups and total number of posts if true. Otherwise,
return 0, 0.
"""
def test_fake_group(group_no: int, groups: list[tuple[int, str, int, str, int, int]]) -> tuple[int, int] {
    group_count = 0;
    post_count = 0;
    (group_no, start, start_ndx, end, end_ndx, count) = groups[group_no - 1];
    if " " not in start or " " not in end {
        return (group_count, post_count);
    }
    our_group = start.split()[0];
    while True {
        if " " not in start or " " not in end {
            return (group_count, post_count);
        }
        if our_group != end.split()[0] {
            return (group_count, post_count);
        }
        if group_no >= len(groups) {
            return (group_count, post_count);
        }
        group_no += 1;
        group_count += 1;
        post_count += count;
        (group_no, start, start_ndx, end, end_ndx, count) = groups[group_no - 1];
        if " " not in start or " " not in end {
            return (group_count, post_count);
        }
        if start.split()[0] != our_group {
            return (group_count, post_count);
        }
    }
}