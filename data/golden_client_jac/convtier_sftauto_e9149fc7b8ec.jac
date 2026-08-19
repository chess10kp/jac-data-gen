def findSecondSmallest(arr: Any) -> object {
    smallest = float('inf');
    secondSmallest = float('inf');
    for num in arr {
        if (num < smallest) {
            secondSmallest = smallest;
            smallest = num;
        } elif ((num > smallest) and (num < secondSmallest)) {
            secondSmallest = num;
        }
    }
    return secondSmallest;
}



with entry {
    print(findSecondSmallest([]));
}
