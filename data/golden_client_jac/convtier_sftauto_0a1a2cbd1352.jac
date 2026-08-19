def findMaxElement(`root: Any) -> object {
    maxElement = float('-inf');
    current = `root;
    while current {
        if (current.val > maxElement) {
            maxElement = current.val;
        }
        if current.right {
            current = current.right;
        } else {
            current = current.left;
        }
    }
    return maxElement;
}



with entry {
    print(findMaxElement(0));
}
