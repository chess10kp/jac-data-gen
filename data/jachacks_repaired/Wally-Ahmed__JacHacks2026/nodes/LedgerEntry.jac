import from datetime { datetime }

node LedgerEntry {
    has entry_id: str = "";
    has entry_type: str = "";
    has asset: str = "USDC";
    has amount: float = 0.0;
    has direction: str = "internal";
    has reference_id: str = "";
    has note: str = "";
    has created_at: str = "";

    def postinit {
        if not self.created_at {
            self.created_at = datetime.now().isoformat();
        }
    }
}
