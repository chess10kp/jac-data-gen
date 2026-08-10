"""Find the element with the smallest height that appears in both given lists.

The height of an element here is defined as the maximum over the indices where
it occurs in the two lists.
"""
def find_lowest_common_in_paths(path_a: list, path_b: list) -> tuple {
    common_elements = [];
    heights = [];
    for element in path_a {
        if element in path_b {
            height = max(path_a.index(element), path_b.index(element));
            common_elements.append(element);
            heights.append(height);
        }
    }
    if not heights {
        raise ValueError(
            'No common nodes in given paths {} and {}.'.format(
                [n.words for n in path_a], [n.words for n in path_b]
            )
        );
    }
    min_height = min(heights);
    argmin_height = heights.index(min_height);
    lowest_common = common_elements[argmin_height];
    assert min_height > 0, 'The lowest common ancestor between two distinct '
    'leaves cannot be a leaf.';
    return (lowest_common, min_height);
}