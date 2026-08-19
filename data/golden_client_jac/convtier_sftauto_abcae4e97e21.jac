def isValidBST(`root: Any) -> object {
    stack = [];
    prev = float('-inf');
    while (stack or `root) {
        while `root {
            stack.append(`root);
            `root = `root.left;
        }
        `root = stack.pop();
        if (`root.val <= prev) {
            return False;
        }
        prev = `root.val;
        `root = `root.right;
    }
    return True;
}



with entry {
    print(isValidBST(0));
}
