# integrations/discord.jac — Discord webhook notification (send only, no bot).

def notify_discord(pr_number: str, risk: str, summary: str) -> None;

def notify_discord_error(pr_number: str, error_message: str) -> None;

def notify_discord_incident(payload: dict) -> None;

def notify_discord_escalation(payload: dict) -> None;

def notify_discord_gap_digest(payload: dict) -> None;

def discord_post_content(content: str) -> None;
