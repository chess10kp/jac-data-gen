"""
in level order traversal of complete binary tree,
left = 2*i+1
right = 2*i+2
"""
def is_min_heap(level_order: list[int]) -> bool {
    length = len(level_order);
    for index in range(int(length / 2 - 1), -1, -1) {
        left_index = 2 * index + 1;
        right_index = left_index + 1;
        if left_index < length and level_order[left_index] < level_order[index] {
            return False;
        }
        if right_index < length and level_order[right_index] < level_order[index] {
            return False;
        }
    }
    return True;
}