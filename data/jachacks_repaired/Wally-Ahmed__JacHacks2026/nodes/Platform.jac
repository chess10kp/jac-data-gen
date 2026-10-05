import from datetime { datetime }
import os;

node Platform {
    has platform_id: str = "platform";
    has name: str = "";
    has environment: str = "";
    has default_chain: str = "";
    has default_asset: str = "";
    has status: str = "active";
    has created_at: str = "";

    def postinit {
        if not self.name {
            self.name = os.getenv("PLATFORM_NAME") or "FILL_ME_PLATFORM_NAME";
        }
        if not self.environment {
            self.environment = os.getenv("APP_ENV") or "dev";
        }
        if not self.default_chain {
            self.default_chain = os.getenv("DEFAULT_CHAIN") or "base";
        }
        if not self.default_asset {
            self.default_asset = os.getenv("DEFAULT_ASSET") or "USDC";
        }
        if not self.created_at {
            self.created_at = datetime.now().isoformat();
        }
    }
}
