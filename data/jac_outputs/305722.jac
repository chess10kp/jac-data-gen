"""Merge two sorted lists of numbers into one sorted list."""
def merge(nums1: list[int], nums2: list[int]) -> list[int] {
    merged = list();
    while len(nums1) != 0 and len(nums2) != 0 {
        if nums1[0] <= nums2[0] {
            merged.append(nums1.pop(0));
        } else {
            merged.append(nums2.pop(0));
        }
    }
    while len(nums1) != 0 {
        merged.append(nums1.pop(0));
    }
    while len(nums2) != 0 {
        merged.append(nums2.pop(0));
    }
    return merged;
}