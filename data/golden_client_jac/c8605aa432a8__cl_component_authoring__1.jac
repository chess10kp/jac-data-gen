def handle_submit {
    if len(value) == 0 {
        skip;   # early return -- lowers to `return;`, not `continue`
    }
    value = "submitted";
}
