import from datetime { datetime }
import os;
import from nodes.IntegrationConfig { IntegrationConfig }

def env_or(env_name: str, fallback: str) -> str {
    value = os.getenv(env_name);
    if value {
        return value;
    }
    return fallback;
}

def ensure_config(provider: str, label: str, api_key: str = "", secret_key: str = "", webhook_secret: str = "", rpc_url: str = "", treasury_wallet: str = "", usdc_contract: str = "", chain_id: str = "8453", mode: str = "test") -> IntegrationConfig {
    for cfg in [root()-->][?:IntegrationConfig] {
        if cfg.provider == provider {
            cfg.label = label;
            cfg.api_key = api_key;
            cfg.secret_key = secret_key;
            cfg.webhook_secret = webhook_secret;
            cfg.rpc_url = rpc_url;
            cfg.treasury_wallet = treasury_wallet;
            cfg.usdc_contract = usdc_contract;
            cfg.chain_id = chain_id;
            cfg.mode = mode;
            cfg.updated_at = datetime.now().isoformat();
            return cfg;
        }
    }
    return (root() ++> IntegrationConfig(
        config_id=provider + "_config",
        provider=provider,
        label=label,
        api_key=api_key,
        secret_key=secret_key,
        webhook_secret=webhook_secret,
        rpc_url=rpc_url,
        treasury_wallet=treasury_wallet,
        usdc_contract=usdc_contract,
        chain_id=chain_id,
        mode=mode,
    ))[0];
}

def:pub seed_demo_config() -> list[IntegrationConfig] {
    stripe = ensure_config(
        provider="stripe",
        label="Stripe Checkout",
        api_key=env_or("STRIPE_PUBLISHABLE_KEY", "pk_test_FILL_ME_STRIPE_PUBLISHABLE_KEY"),
        secret_key=env_or("STRIPE_SECRET_KEY", "sk_test_FILL_ME_STRIPE_SECRET_KEY"),
        webhook_secret=env_or("STRIPE_WEBHOOK_SECRET", "whsec_FILL_ME_STRIPE_WEBHOOK_SECRET"),
        mode=env_or("APP_MODE", "test"),
    );
    wallets = ensure_config(
        provider="wallet_provider",
        label=env_or("WALLET_PROVIDER_NAME", "FILL_ME_WALLET_PROVIDER"),
        api_key=env_or("WALLET_PROVIDER_API_KEY", "FILL_ME_WALLET_PROVIDER_API_KEY"),
        secret_key=env_or("WALLET_PROVIDER_SECRET", "FILL_ME_WALLET_PROVIDER_SECRET"),
        treasury_wallet=env_or("TREASURY_WALLET", "0xFILL_ME_TREASURY_WALLET"),
        mode=env_or("APP_MODE", "test"),
    );
    rpc = ensure_config(
        provider="rpc",
        label=env_or("DEFAULT_CHAIN", "Base RPC"),
        rpc_url=env_or("RPC_URL", "https://FILL_ME_RPC_URL"),
        usdc_contract=env_or("USDC_CONTRACT", "0xFILL_ME_USDC_CONTRACT"),
        chain_id=env_or("CHAIN_ID", "8453"),
        mode=env_or("APP_MODE", "test"),
    );
    return [stripe, wallets, rpc];
}

def:pub list_configs() -> list[IntegrationConfig] {
    return [root()-->][?:IntegrationConfig];
}
