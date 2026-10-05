import from datetime { datetime }

node Payout {
    has payout_id: str = "";
    has invoice_id: str = "";
    has asset: str = "USDC";
    has amount: float = 0.0;
    has destination_address: str = "";
    has tx_hash: str = "";
    has status: str = "pending";
    has broadcast_at: str = "";
    has confirmed_at: str = "";
    has failure_reason: str = "";
    has created_at: str = "";
    has updated_at: str = "";

    def postinit {
        now = datetime.now().isoformat();
        if not self.created_at { self.created_at = now; }
        if not self.updated_at { self.updated_at = now; }
    }
}
