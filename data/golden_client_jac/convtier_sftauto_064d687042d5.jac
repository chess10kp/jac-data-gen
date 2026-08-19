def reverse_stack(stack: Any) -> object {
    if (len(stack) == 1) {
        return stack;
    }
    top = stack.pop();
    reversed_stack = reverse_stack(stack);
    insert_at_bottom(reversed_stack, top);
    return reversed_stack;
}



with entry {
    print(reverse_stack([-9]));
    print(reverse_stack(['a']));
}
