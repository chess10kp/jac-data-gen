"""Implementation of Bubble sort.

Takes integer list as input,
returns sorted list."""
def bubble_sort(x: list[int]) -> list[int] {
    print("Starting Bubble sort on following list:\n", x);
    loop = 0;
    unsorted = True;
    while unsorted {
        loop += 1;
        print("Bubble sort is in iteration: ", loop);
        changes = 0;
        for i in range(len(x) - 1) {
            if x[i] > x[i + 1] {
                print("Bubble sort is changing position of: ", x[i], "and", x[i + 1]);
                j = x[i];
                x[i] = x[i + 1];
                x[i + 1] = j;
                changes += 1;
            }
        }
        if changes == 0 {
            unsorted = False;
        }
    }
    print("Bubble sort is finished. Sorted list is: \n", x);
    return x;
}