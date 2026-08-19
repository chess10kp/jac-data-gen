def example() {
    text = "hello\nworld";

    f"{text}";              # "hello\nworld" (default str())
    f"{text!s}";            # "hello\nworld" (explicit str())
    f"{text!r}";            # "'hello\\nworld'" (repr())
    f"{text!a}";            # "'hello\\nworld'" (ascii())
}
