"""Selects the useful fields from the repos

    Arguments:
        repos {list} -- the list of repos to be cleaned
        repo_count {int} -- the number of repos

    Returns:
        {dict} -- the standard output format for the program
    """
def get_useful_fields(repos: Any, repo_count: Any) -> object {
    filtered_repos = [];
    for repo in repos {
        filtered_repos.append(
            {
                "name": repo["name"],
                "language": repo["language"],
                "stars": repo["stargazers_count"],
                "forks": repo["forks_count"],
                "issues": repo["open_issues_count"]
            }
        );
    }
    return {"Number of repositories": repo_count, "Repositories": filtered_repos};
}