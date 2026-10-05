import from datetime { datetime }

node PaymentEvent {
    has event_id: str = "";
    has provider: str = "stripe";
    has provider_event_id: str = "";
    has event_type: str = "";
    has payment_status: str = "pending";
    has payload_hash: str = "placeholder_payload_hash";
    has received_at: str = "";
    has processed_at: str = "";

    def postinit {
        now = datetime.now().isoformat();
        if not self.received_at { self.received_at = now; }
        if not self.processed_at { self.processed_at = now; }
    }
}
