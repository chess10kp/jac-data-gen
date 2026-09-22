"""Find start date from participants, host logins, and repository cache."""
def get_start_date(
    participants: list[dict[str, str]],
    host_dict: dict[str, str],
    repo_dates: dict[str, str],
    repo: str
) -> str {
    if repo not in repo_dates {
        for user in participants {
            try {
                cur_username = user["login"];
            } except (TypeError, KeyError) {
                continue;
            }
            if cur_username in host_dict {
                start_date = host_dict[cur_username];
                repo_dates[repo] = start_date;
                return start_date;
            }
        }
        return "unknown";
    }
    return repo_dates[repo];
}