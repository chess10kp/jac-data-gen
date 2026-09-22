"""Function to return a sorted list using the selection sort algorithm."""
def selection_sort(marks: list[int]) -> list[int] {
    for i in range(len(marks)) {
        min = i;
        for j in range(i + 1, len(marks)) {
            if marks[min] > marks[j] {
                min = j;
            }
        }
        (marks[i], marks[min]) = (marks[min], marks[i]);
    }
    return marks;
}