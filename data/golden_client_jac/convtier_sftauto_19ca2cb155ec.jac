def augment_list(original_list: Any) -> object {
    augmented_list = [];
    for i in range(len(original_list)) {
        if (original_list[i] == 0) {
            augmented_list.append(0);
            for j in range(5) {
                i += 1;
                if (i >= len(original_list)) {
                    break;
                }
            }
        }
        augmented_list.append(original_list[i]);
        if (((i + 1) % 4) == 0) {
            augmented_list.extend(([0] * 5));
        }
    }
    return augmented_list;
}



with entry {
    print(augment_list('hello'));
    print(augment_list('Racecar'));
    print(augment_list('abcabc'));
}
