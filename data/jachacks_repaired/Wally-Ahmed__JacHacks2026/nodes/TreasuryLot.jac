import from datetime { datetime }

node TreasuryLot {
    has treasury_lot_id: str = "";
    has asset: str = "USDC";
    has chain: str = "base";
    has amount: float = 0.0;
    has available_amount: float = 0.0;
    has reserved_amount: float = 0.0;
    has source: str = "treasury";
    has status: str = "available";
    has created_at: str = "";

    def postinit {
        if not self.created_at {
            self.created_at = datetime.now().isoformat();
        }
    }
}
