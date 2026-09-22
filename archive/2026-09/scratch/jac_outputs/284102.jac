"""Merge two sorted lists and count split inversions."""
def merge_and_count_split_inv(B: list[int], C: list[int]) -> tuple[list[int], int] {
    merged = [];
    inv_counter = 0;
    item_b = None;
    item_c = None;
    while B or C or item_b or item_c {
        if not item_b and B {
            item_b = B.pop(0);
        }
        if not item_c and C {
            item_c = C.pop(0);
        }
        if item_b and item_c {
            if item_b <= item_c {
                merged.append(item_b);
                item_b = None;
            } else {
                merged.append(item_c);
                if item_b {
                    inv_counter += 1 + len(B);
                }
                item_c = None;
            }
        } else {
            if item_b {
                merged.append(item_b);
                item_b = None;
            }
            if item_c {
                merged.append(item_c);
                item_c = None;
            }
        }
    }
    return (merged, inv_counter);
}