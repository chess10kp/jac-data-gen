"""
    replace potentially problematic characters in provided string, a branch name

    e.g. copr says:
        Name must contain only letters, digits, underscores, dashes and dots.
    """
def sanitize_branch_name(branch_name: str) -> str {
    offenders = "!@#$%^&*()+={[}]|\\'\":;<,>/?~`";
    for o in offenders {
        branch_name = branch_name.replace(o, "-");
    }
    return branch_name;
}