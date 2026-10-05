"""
Vouch v2: Session Hijack Detector
Validates session event provenance and detects automated
injection attempts by checking timing patterns and content consistency.
"""

import from ._base { BlockReason, pass_result, block_result, confirm_result }

walker CheckSessionIntegrity {
    has events: list[dict] = [];
    # Each event: {timestamp_epoch, source_app, content_type, content_length}
    has max_events_per_second: int = 3;
    has min_interval_ms: int = 200;

    can check with entry {
        if len(self.events) < 2 {
            report pass_result("session_hijack");
            disengage;
        }

        # Sort by timestamp
        sorted_events = sorted(self.events, key=lambda (e: dict) { e.get("timestamp_epoch", 0) });

        # Check for rapid-fire events (bot behavior)
        rapid_count = 0;
        for i in range(1, len(sorted_events)) {
            interval_ms = (sorted_events[i]["timestamp_epoch"] - sorted_events[i-1]["timestamp_epoch"]) * 1000;
            if interval_ms < self.min_interval_ms {
                rapid_count += 1;
            }
        }

        if rapid_count > 2 {
            report block_result(
                "session_hijack",
                BlockReason.CUSTOM,
                f"Automated session detected: {rapid_count} events with <{self.min_interval_ms}ms intervals. This looks like bot-generated share events, not human behavior."
            );
            disengage;
        }

        # Check for suspiciously uniform content
        content_types = set([e.get("content_type", "") for e in sorted_events]);
        source_apps = set([e.get("source_app", "") for e in sorted_events]);
        content_lengths = [e.get("content_length", 0) for e in sorted_events];

        # All events from same source with identical content lengths = suspicious
        if len(source_apps) == 1 and len(content_lengths) > 3 {
            avg_len = sum(content_lengths) / len(content_lengths);
            variance = sum([(l - avg_len)**2 for l in content_lengths]) / len(content_lengths);
            if variance < 10 {  # Nearly identical content lengths
                report confirm_result(
                    "session_hijack",
                    f"Suspicious session pattern: {len(sorted_events)} events from '{list(source_apps)[0]}' with near-identical content lengths (variance: {variance:.1f}). May be automated."
                );
                disengage;
            }
        }

        # Check events per second
        if len(sorted_events) >= 2 {
            time_span = sorted_events[-1]["timestamp_epoch"] - sorted_events[0]["timestamp_epoch"];
            if time_span > 0 {
                rate = len(sorted_events) / time_span;
                if rate > self.max_events_per_second {
                    report block_result(
                        "session_hijack",
                        BlockReason.CUSTOM,
                        f"Event rate too high: {rate:.1f} events/second exceeds max of {self.max_events_per_second}. Blocking suspected automated injection."
                    );
                    disengage;
                }
            }
        }

        report pass_result("session_hijack");
    }
}
