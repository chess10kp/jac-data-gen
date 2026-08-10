"""If some command arguments have spaces, quote them. Then concatenate the results."""
def format_cmd(cmd: list[str]) -> str {
    ans = "";
    for val in cmd {
        if " " in val or "\t" in cmd {
            val = '"' + val + '"';
        }
        ans += val + " ";
    }
    return ans;
}