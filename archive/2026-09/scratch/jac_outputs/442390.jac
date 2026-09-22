"""Return a /v1/ss3/subscriptions/<SUBSCRIPTION_ID>/state/away."""
def v3_state_away_json() -> object {
    return {
        "success": True,
        "reason": None,
        "state": "AWAY",
        "lastUpdated": 1534725096,
        "exitDelay": 120
    };
}