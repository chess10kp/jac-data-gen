def majorityElement(nums: List[int]) -> int {
    count = 0;
    candidate = None;
    for num in nums {
        if (count == 0) {
            candidate = num;
            count = 1;
        } elif (num == candidate) {
            count += 1;
        } else {
            count -= 1;
        }
    }
    return candidate;
}



with entry {
    print(majorityElement('hello'));
    print(majorityElement('Racecar'));
    print(majorityElement('abcabc'));
}
