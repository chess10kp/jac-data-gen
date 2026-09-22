"""Returns problem report dict from req_data sent by GitHub hook."""
def build_problem_report(req_data: dict[str, dict[str, str | int | dict[str, str | int | dict[str, str]]]]) -> dict[str, str] {
    return {
        "product": "Ports & Packages",
        "component": "Individual Port(s)",
        "version": "Latest",
        "summary": "GitHub Pull Request #{number}: {title}".format(
            number=req_data['pull_request']['number'],
            title=req_data['pull_request']['title']
        ),
        "description": "{description}\nBy: {name}({name_url})".format(
            description=req_data['pull_request']['body'],
            name=req_data['pull_request']['user']['login'],
            name_url=req_data['pull_request']['user']['url']
        ),
        "url": "{url}".format(url=req_data['pull_request']['html_url'])
    };
}