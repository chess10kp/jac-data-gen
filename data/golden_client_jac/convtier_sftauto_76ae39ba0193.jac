def validate_branch_name(branch_name: Any) -> object {
    if (not branch_name or (len(branch_name) > 50)) {
        return False;
    }
    pattern = r'^feature/[a-z][a-z0-9_]+/[A-Z]{2}$';
    if not re.match(pattern, branch_name) {
        return False;
    }
    return True;
}



with entry {
    print(validate_branch_name(0));
}
