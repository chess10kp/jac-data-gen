"""Write a line like charley does"""
def write_line(
    index: Any, member: Any, stat_text: Any, stat: Any, emoji: Any
) -> object {
    return f"**{index})** {member} \n{emoji} {stat_text}: {stat}";
}