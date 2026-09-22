"""Splits an IAM member into type and optional value."""
def _split_member(member: str) -> list[str] | tuple[str, None] {
    if ':' in member {
        return member.split(':', 1);
    }
    return (member, None);
}