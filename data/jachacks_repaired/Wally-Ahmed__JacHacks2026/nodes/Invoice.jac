import from datetime { datetime, timedelta }

node Invoice {
    has invoice_id: str = "";
    has merchant_id: str = "";
    has reference: str = "";
    has description: str = "";
    has fiat_amount: float = 0.0;
    has fiat_currency: str = "USD";
    has target_asset: str = "USDC";
    has target_chain: str = "base";
    has quoted_asset_amount: float = 0.0;
    has destination_address: str = "";
    has status: str = "created";
    has checkout_url: str = "";
    has expires_at: str = "";
    has created_at: str = "";
    has updated_at: str = "";

    def postinit {
        now = datetime.now().isoformat();
        if not self.created_at { self.created_at = now; }
        if not self.updated_at { self.updated_at = now; }
        if not self.expires_at {
            self.expires_at = (datetime.now() + timedelta(hours=1)).isoformat();
        }
    }
}
