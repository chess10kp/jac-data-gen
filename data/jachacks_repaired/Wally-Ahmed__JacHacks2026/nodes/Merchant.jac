import from datetime { datetime }

node Merchant {
    has merchant_id: str = "";
    has legal_name: str = "";
    has display_name: str = "";
    has email: str = "";
    has status: str = "active";
    has default_chain: str = "base";
    has default_asset: str = "USDC";
    has created_at: str = "";
    has updated_at: str = "";

    def postinit {
        now = datetime.now().isoformat();
        if not self.created_at { self.created_at = now; }
        if not self.updated_at { self.updated_at = now; }
    }
}
