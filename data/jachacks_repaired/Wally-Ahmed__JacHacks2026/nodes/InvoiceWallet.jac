import from datetime { datetime, timedelta }

node InvoiceWallet {
    has invoice_wallet_id: str = "";
    has provider: str = "circle";
    has provider_wallet_id: str = "";
    has provider_wallet_set_id: str = "";
    has provider_ref_id: str = "";
    has provider_state: str = "";
    has custody_type: str = "DEVELOPER";
    has address: str = "";
    has chain: str = "base";
    has asset: str = "USDC";
    has status: str = "created";
    has allowed_destination: str = "";
    has spend_limit: float = 0.0;
    has gas_limit: float = 0.005;
    has expires_at: str = "";
    has retired_at: str = "";
    has created_at: str = "";

    def postinit {
        if not self.created_at {
            self.created_at = datetime.now().isoformat();
        }
        if not self.expires_at {
            self.expires_at = (datetime.now() + timedelta(hours=2)).isoformat();
        }
    }
}
