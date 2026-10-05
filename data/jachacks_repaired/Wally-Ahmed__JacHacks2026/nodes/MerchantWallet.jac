import from datetime { datetime }

node MerchantWallet {
    has wallet_id: str = "";
    has address: str = "";
    has chain: str = "base";
    has asset: str = "USDC";
    has label: str = "primary";
    has verified: bool = False;
    has is_default: bool = True;
    has status: str = "active";
    has created_at: str = "";

    def postinit {
        if not self.created_at {
            self.created_at = datetime.now().isoformat();
        }
    }
}
