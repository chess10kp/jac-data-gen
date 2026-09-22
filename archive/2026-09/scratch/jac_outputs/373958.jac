"""Return the name of the combined model for a repo or organization.

If repo is specified looks for a repo specific model. If repo is
none we return an org wide model.
"""
def _combined_model_name(org: str, repo: str | None = None) -> str {
    if repo {
        return f"{org}/{repo}_combined";
    }
    return f"{org}_combined";
}