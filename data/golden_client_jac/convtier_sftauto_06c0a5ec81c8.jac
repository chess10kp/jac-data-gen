def maxPathSum(`root: Any) -> object {
    max_sum = float('-inf');
    def maxPathSumHelper(`node: Any) -> object {
        nonlocal max_sum;
        if not `node {
            return 0;
        }
        left_sum = max(0, maxPathSumHelper(`node.left));
        right_sum = max(0, maxPathSumHelper(`node.right));
        max_sum = max(max_sum, (`node.val + left_sum + right_sum));
        return (`node.val + max(left_sum, right_sum));
    }
    maxPathSumHelper(`root);
    return max_sum;
}



with entry {
    print(maxPathSum(0));
}
