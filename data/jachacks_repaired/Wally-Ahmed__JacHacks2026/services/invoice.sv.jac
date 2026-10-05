import from datetime { datetime, timedelta }
import from nodes.Invoice { Invoice }
import from nodes.Merchant { Merchant }
import from nodes.MerchantWallet { MerchantWallet }
import from services.merchant { find_merchant }

def find_invoice(invoice_id: str) -> Invoice {
    for invoice in [root-->][?:Invoice] {
        if invoice.invoice_id == invoice_id or jid(invoice) == invoice_id {
            return invoice;
        }
    }
}

def resolve_destination_wallet(merchant: Merchant, destination_wallet: str) -> str {
    if destination_wallet {
        return destination_wallet;
    }
    for wallet in [merchant-->][?:MerchantWallet] {
        if wallet.is_default {
            return wallet.address;
        }
    }
    for wallet in [merchant-->][?:MerchantWallet] {
        return wallet.address;
    }
    return "";
}

def:pub create_invoice(merchant_id: str, reference: str, fiat_amount: float, fiat_currency: str = "USD", destination_wallet: str = "", chain: str = "base", quoted_asset_amount: float = 0.0, description: str = "") -> Invoice {
    merchant = find_merchant(merchant_id);
    invoice = merchant ++> Invoice(
        invoice_id="invoice_" + str(len([root-->][?:Invoice]) + 1),
        merchant_id=merchant.merchant_id,
        reference=reference,
        description=description,
        fiat_amount=fiat_amount,
        fiat_currency=fiat_currency,
        target_chain=chain,
        quoted_asset_amount=quoted_asset_amount,
        destination_address=resolve_destination_wallet(merchant, destination_wallet),
        status="created",
    );
    return invoice;
}

def:pub get_invoice(invoice_id: str) -> Invoice {
    return find_invoice(invoice_id);
}

def:pub list_invoices() -> list[Invoice] {
    return [root-->][?:Invoice];
}

def:pub list_merchant_invoices(merchant_id: str) -> list[Invoice] {
    merchant = find_merchant(merchant_id);
    return [merchant-->][?:Invoice];
}

def:pub expire_invoice(invoice_id: str) -> Invoice {
    invoice = find_invoice(invoice_id);
    invoice.status = "expired";
    invoice.updated_at = datetime.now().isoformat();
    return invoice;
}
