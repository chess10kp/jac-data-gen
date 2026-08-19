def findSmallestOddPrimeIndex(arr: Any) -> object {
    smallestOddPrimeIndex = -1;
    for i in range(len(arr)) {
        if isOddPrime(arr[i]) {
            if (smallestOddPrimeIndex == -1) {
                smallestOddPrimeIndex = i;
            } elif (arr[i] < arr[smallestOddPrimeIndex]) {
                smallestOddPrimeIndex = i;
            }
        }
    }
    return smallestOddPrimeIndex;
}



with entry {
    print(findSmallestOddPrimeIndex([]));
}
