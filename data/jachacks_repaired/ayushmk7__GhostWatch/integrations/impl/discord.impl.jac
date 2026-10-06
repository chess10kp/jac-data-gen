# integrations/impl/discord.impl.jac

import from os { environ }
import requests;

impl discord_post_content(content: str) -> None {
    webhook_url = environ.get("DISCORD_WEBHOOK_URL", "");
    if not webhook_url {
        print("DISCORD_WEBHOOK_URL not set — skipping Discord");
        return;
    }
    payload = {"username": "GhostWatch", "content": content};
    try {
        resp = requests.post(webhook_url, json=payload, timeout=10);
        code = int(getattr(resp, "status_code", 0));
        if code not in [200, 204] {
            print(f"Discord webhook returned {code}");
        }
    } except Exception as e { # jac:ignore[W2052]
        print(f"Discord post failed: {e}");
    }
}

impl notify_discord(pr_number: str, risk: str, summary: str) -> None {
    risk_emoji = {
        "CRITICAL": "🔴",
        "HIGH": "🟠",
        "MEDIUM": "🟡",
        "LOW": "🟢",
        "CLEAN": "✅"
    };
    emoji = risk_emoji.get(risk.upper(), "⚪");
    discord_post_content(
        f"{emoji} **PR #{pr_number} analyzed — Risk: {risk.upper()}**\n{summary}"
    );
}

impl notify_discord_error(pr_number: str, error_message: str) -> None {
    discord_post_content(f"⚠️ **PR #{pr_number} analysis failed** — {error_message}");
}

impl notify_discord_incident(payload: dict) -> None {
    dep = payload.get("dependency_name", "?");
    status = payload.get("status", "?");
    repo = payload.get("repo", "?");
    discord_post_content(
        f"🛡️ **GhostWatch incident** [{status}]\nRepo: `{repo}`\nDependency: `{dep}`\n{payload.get('summary', '')}"
    );
}

impl notify_discord_escalation(payload: dict) -> None {
    discord_post_content(
        f"⏰ **Escalation reminder**\n{payload.get('dedupe_key', '')}\n{payload.get('note', '')}"
    );
}

impl notify_discord_gap_digest(payload: dict) -> None {
    n = len(payload.get("suggestions", []));
    sha = payload.get("merge_commit_sha", "")[:8];
    discord_post_content(f"📊 **Gap analysis** merge `{sha}` — {n} contributor suggestions persisted.");
}
