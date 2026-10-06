# walkers/ghostwatch/github_system2_webhook.jac — Validates GitHub signatures; dispatches System 2 walkers.

walker:pub GitHubSystem2WebhookWalker {
    has event_type: str = "";
    has payload: dict = {};
    has signature: str = "";
    has raw_body: str = "";
    has reports: list = [];

    can run with Root entry;
}
