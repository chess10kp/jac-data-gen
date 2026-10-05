import from datetime { datetime }

node CheckoutSession {
    has checkout_id: str = "";
    has provider: str = "stripe";
    has provider_session_id: str = "";
    has provider_payment_intent_id: str = "";
    has hosted_url: str = "";
    has amount_total: float = 0.0;
    has currency: str = "USD";
    has status: str = "created";
    has created_at: str = "";
    has updated_at: str = "";

    def postinit {
        now = datetime.now().isoformat();
        if not self.created_at { self.created_at = now; }
        if not self.updated_at { self.updated_at = now; }
    }
}
