import from datetime { datetime }

node IntegrationConfig {
    has config_id: str = "";
    has provider: str = "";
    has label: str = "";
    has api_key: str = "";
    has secret_key: str = "";
    has webhook_secret: str = "";
    has rpc_url: str = "";
    has treasury_wallet: str = "";
    has usdc_contract: str = "";
    has chain_id: str = "";
    has enabled: bool = True;
    has mode: str = "test";
    has updated_at: str = "";

    def postinit {
        if not self.updated_at {
            self.updated_at = datetime.now().isoformat();
        }
    }
}
