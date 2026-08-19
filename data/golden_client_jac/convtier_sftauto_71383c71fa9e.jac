def findGreaterValues(`root: Any) -> object {
    count = 0;
    result = [];
    def inorderTraversal(`node: Any) -> object {
        nonlocal count;
        if `node {
            inorderTraversal(`node.left);
            count += 1;
            result.append(count);
            inorderTraversal(`node.right);
        }
    }
    inorderTraversal(`root);
    return result;
}



with entry {
    print(findGreaterValues(0));
}
