Small one in the alerts code (`binsight/jac_app/extensions/walkers/alert_walkers.jac`): `ListOpenAlerts` takes a `min_severity` argument but it doesn't do anything — managers asking for "high and up" still get every low-priority bin alert.

Please make `min_severity` actually filter. Severities go low < medium < high < critical, and people type them in all sorts of casing, so "HIGH" and "high" should behave the same. It still has to work together with the `hall_id` filter. While you're there, return the alerts sorted most severe first so the critical stuff is at the top.

Keep the response shape the same (`{"open_alerts": [...]}`) so the frontend doesn't break.
