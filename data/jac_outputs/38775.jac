"""
Apply apriori principle
    'if an item set is frequent,
    then all of its subsets must also be frequent.'
"""
def applyAprioriPrinciple(item_sets: list[list], selected_item_sets: list[tuple]) -> list[list] {
    if len(selected_item_sets) == 0 {
        return [];
    }
    return_item_sets = [];
    subset_len: int | None = None;
    for s in item_sets {
        all_subset_present = True;
        if not subset_len {
            subset_len = len(s) - 1;
        }
        l = s + s[0:(subset_len - 1)];
        for i in range(len(s)) {
            subset = tuple(sorted(l[i:(i + subset_len)]));
            if subset not in selected_item_sets {
                print(
                    'Subset',
                    subset,
                    'not present, ignoring itemset',
                    s,
                    'as per apriori principle'
                );
                all_subset_present = False;
                break;
            }
        }
        if all_subset_present {
            return_item_sets.append(s);
        }
    }
    return return_item_sets;
}