"""
Vouch built-in: Rate Guard
Limits how often specific action types can occur within a time window.
Uses Jac graph nodes to maintain per-action-type counters.
This is stateful -- it requires Jac's graph model to implement cleanly.
"""

import from ._base { BlockReason, pass_result, block_result }

node ActionCounter {
    has action_type: str;
    has count: int = 0;
    has window_start_epoch: int = 0;
    has limit: int = 10;
    has window_seconds: int = 60;
}

walker CheckRateLimit {
    has action_type: str;
    has limit: int = 10;
    has window_seconds: int = 60;
    has current_epoch: int = 0;

    can check with entry {
        # Find or create counter node for this action type
        counters = [root-->][?:ActionCounter];
        matching = [c for c in counters if c.action_type == self.action_type];

        if not matching {
            counter = ActionCounter(
                action_type=self.action_type,
                count=1,
                window_start_epoch=self.current_epoch,
                limit=self.limit,
                window_seconds=self.window_seconds
            );
            root ++> counter;
            report pass_result("rate_guard");
            disengage;
        }

        counter = matching[0];

        # Reset window if expired
        window_age = self.current_epoch - counter.window_start_epoch;
        if window_age > counter.window_seconds {
            counter.count = 1;
            counter.window_start_epoch = self.current_epoch;
            report pass_result("rate_guard");
            disengage;
        }

        # Check limit
        if counter.count >= counter.limit {
            report block_result(
                "rate_guard",
                BlockReason.RATE_EXCEEDED,
                f"'{self.action_type}' has been called {counter.count} times "
                f"in the last {counter.window_seconds} seconds. Limit: {counter.limit}."
            );
            disengage;
        }

        counter.count += 1;
        report pass_result("rate_guard");
    }
}
