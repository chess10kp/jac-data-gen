import from config {
    seed_demo_config,
    list_configs
}
import from app_platform {
    Platform,
    bootstrap_platform,
    get_platform_overview
}
import from nodes.IntegrationConfig { IntegrationConfig }
import from nodes.Merchant { Merchant }
import from nodes.MerchantWallet { MerchantWallet }
import from nodes.Invoice { Invoice }
import from nodes.CheckoutSession { CheckoutSession }
import from nodes.PaymentEvent { PaymentEvent }
import from nodes.InvoiceWallet { InvoiceWallet }
import from nodes.TreasuryLot { TreasuryLot }
import from nodes.Payout { Payout }
import from nodes.LedgerEntry { LedgerEntry }
import from nodes.AuditEvent { AuditEvent }
import from services.merchant {
    create_merchant as create_merchant_service,
    get_merchant as get_merchant_service,
    list_merchants as list_merchants_service,
    add_merchant_wallet as add_merchant_wallet_service,
    list_merchant_wallets as list_merchant_wallets_service,
    delete_merchant_wallet as delete_merchant_wallet_service
}
import from services.invoice {
    create_invoice,
    get_invoice,
    list_invoices,
    list_merchant_invoices,
    expire_invoice
}
import from services.payment {
    create_checkout_session,
    create_checkout_for_wallet,
    create_card_payment,
    create_card_payment_for_merchant,
    get_checkout,
    stripe_webhook,
    mark_payment_succeeded,
    mark_payment_failed
}
import from services.wallets {
    create_invoice_wallet,
    get_invoice_wallet,
    retire_invoice_wallet
}
import from services.settlement {
    reserve_treasury,
    fund_invoice_wallet,
    create_payout,
    broadcast_payout,
    confirm_payout,
    retry_payout,
    get_failed_payouts,
    send_usdc
}
import from services.audit {
    get_invoice_ledger,
    get_invoice_audit,
    reconcile_invoice
}

def:pub create_merchant(legal_name: str, email: str, display_name: str = "") -> Merchant {
    return create_merchant_service(
        legal_name=legal_name,
        email=email,
        display_name=display_name,
    );
}

def:pub get_merchant(merchant_id: str) -> Merchant {
    return get_merchant_service(merchant_id=merchant_id);
}

def:pub list_merchants() -> list[Merchant] {
    return list_merchants_service();
}

def:pub add_merchant_wallet(merchant_id: str, chain: str = "base", asset: str = "USDC", label: str = "primary") -> MerchantWallet {
    print("add_merchant_wallet route hit", merchant_id, chain, asset, label);
    return add_merchant_wallet_service(
        merchant_id=merchant_id,
        chain=chain,
        asset=asset,
        label=label,
    );
}

def:pub list_merchant_wallets(merchant_id: str) -> list[MerchantWallet] {
    return list_merchant_wallets_service(merchant_id=merchant_id);
}

def:pub delete_merchant_wallet(merchant_id: str, wallet_id: str) -> dict {
    return delete_merchant_wallet_service(
        merchant_id=merchant_id,
        wallet_id=wallet_id,
    );
}

import from frontend { app as ClientApp }

def:pub app -> JsxElement {
    return <ClientApp />;
}
