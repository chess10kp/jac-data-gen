"""
    output # of pairs having k diff

    Array = unsorted, non empty, distinct, pos ints

    ASSUME
    - every pair of int instances that meet k diff are counted,
        even if it's same values as another pair
    - cannot pair an element w/ itself
    - can use built in sorting func

    Intuition:
    - need to check every element at least once

    Approach:

    1. Brute Force - quadratic
        a) try all the pairs
        b) count up the ones that are k apart

    2. Sorting - n log n + n --> linearithmic time
        Ex: [1, 5, 3, 4, 2], k = 2
            [1, 2, 3, 4, 5]
             ^     ^
                   ^     ^
        a) sort the array
        b) search for the pairs w/ 2 pointers + count

    3) HashSet --> linear time + space
        a) make a set of all elements
        b) go through each element, in the array:
            - calculate it's comp, given k
            - check if comp in set
                - increment count of pairs
        [1, 5, 3, 4, 2]
         ^. ^. ^. ^  ^
        {1, 5, 3, 4, 2}

        count = 0, 1, 2, 3

        - for now I'll go with the HashSet option, but
        if the problem expanded to include duplicates,
        or the k could be negative, then this would
        need to be revised


    Edge Cases:
    - all same elements - return (n - 1) + (n - 2) + (n - 3)...
        --> "Triangular Series" - n(n - 1) / 2 (prove if asked)
    -
    """
def pairs(k: int, arr: list[int]) -> int {
    values = set(arr);
    pair_count = 0;
    for num in arr {
        complement = num + k;
        if complement in values {
            pair_count += 1;
        }
    }
    return pair_count;
}