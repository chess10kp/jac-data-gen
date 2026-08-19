def gnome_sort(array: Any) -> object {
    index = 0;
    while (index < len(array)) {
        if (index == 0) {
            index += 1;
        } elif (array[index] >= array[(index - 1)]) {
            index += 1;
        } else {
            (array[index], array[(index - 1)]) = (array[(index - 1)], array[index]);
            index -= 1;
        }
    }
    return array;
}



with entry {
    print(gnome_sort([]));
}
