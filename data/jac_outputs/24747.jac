"""
convert array 1 to a set object
loop through the second array and check if item in second array exists in the created set
"""
def contains_common_item_3(arr1: list[int], arr2: list[int]) -> bool {
    array1_set = set(arr1);
    for item2 in arr2 {
        if item2 in array1_set {
            return True;
        }
    }
    return False;
}