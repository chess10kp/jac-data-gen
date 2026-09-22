"""Extract the email between '<' and '>' in a commit message string."""
def extract_email(commit_email: str) -> str {
    return commit_email[commit_email.find("<") + 1:commit_email.rfind(">")];
}