cl {
    def:pub Subscriber() -> JsxElement {
        has events: list = [];

        can with entry {
            subscribe_to_events();
        }

        # Cleanup on unmount
        can with exit {
            cleanup_subscriptions();
        }

        return <p>{len(events)} events</p>;
    }
}
