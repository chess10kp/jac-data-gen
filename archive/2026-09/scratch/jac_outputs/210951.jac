"""Sorts by using the radix sort. This version only works with positive integers. Sorts by creating buckets and putting each number in to its corresponding bucket by looking at each consecutive digit."""
def radix_sort(lst: list[int], base: int = 10) -> list[int] {
    if len(lst) < 2 {
        return lst;
    }
    def lst_to_buckets(lst: list[int], base: int, iteration: int) -> list[list[int]] {
        buckets = [[] for _ in range(base)];
        for number in lst {
            digit = (number // (base ** iteration)) % base;
            buckets[digit].append(number);
        }
        return buckets;
    }
    def buckets_to_lst(buckets: list[list[int]]) -> list[int] {
        return [number for bucket in buckets for number in bucket];
    }
    maxval = max(lst);
    itr = 0;
    while (base ** itr) <= maxval {
        lst = buckets_to_lst(lst_to_buckets(lst, base, itr));
        itr += 1;
    }
    return lst;
}