import from datetime { datetime, timedelta }
import os;
import from uuid { uuid4 }
import from dotenv { load_dotenv }
import from json { loads }
import from subprocess { run }
import from nodes.InvoiceWallet { InvoiceWallet }
import from nodes.Invoice { Invoice }
import from services.invoice { find_invoice }

def find_invoice_wallet(invoice: Invoice) -> InvoiceWallet {
    for wallet in [invoice-->][?:InvoiceWallet] {
        return wallet;
    }
}

def env_required(name: str) -> str {
    load_dotenv();
    value = os.getenv(name);
    if not value {
        raise Exception("Missing required environment variable: " + name);
    }
    return value;
}

def circle_blockchain_for(chain: str) -> str {
    load_dotenv();
    lowered = chain.lower();
    if lowered == "base" {
        return os.getenv("CIRCLE_BLOCKCHAIN", "BASE-SEPOLIA");
    }
    if lowered == "ethereum" or lowered == "eth" {
        return "ETH-SEPOLIA";
    }
    if lowered == "polygon" or lowered == "matic" {
        return "MATIC-AMOY";
    }
    return os.getenv("CIRCLE_BLOCKCHAIN", "BASE-SEPOLIA");
}

def create_circle_developer_wallet(invoice: Invoice) -> dict {
    env_required("CIRCLE_ENTITY_SECRET");
    env_required("CIRCLE_WALLET_SET_ID");

    result = run(
        [
            "node",
            "scripts/circle-create-wallet.mjs",
            circle_blockchain_for(invoice.target_chain),
            "Invoice " + invoice.invoice_id,
            invoice.invoice_id,
        ],
        cwd=os.getcwd(),
        capture_output=True,
        text=True,
    );
    if result.returncode != 0 {
        raise Exception("Circle wallet creation failed: " + result.stderr);
    }
    return loads(result.stdout);
}

def:pub create_invoice_wallet(invoice_id: str) -> InvoiceWallet {
    invoice = find_invoice(invoice_id);
    existing = find_invoice_wallet(invoice);
    if existing {
        return existing;
    }
    circle_wallet = create_circle_developer_wallet(invoice);
    wallet = invoice ++> InvoiceWallet(
        invoice_wallet_id="invoice_wallet_" + invoice.invoice_id,
        provider="circle",
        provider_wallet_id=circle_wallet["wallet_id"],
        provider_wallet_set_id=circle_wallet["wallet_set_id"],
        provider_ref_id=circle_wallet["ref_id"],
        provider_state=circle_wallet["state"],
        custody_type=circle_wallet["custody_type"],
        address=circle_wallet["address"],
        chain=invoice.target_chain,
        allowed_destination=invoice.destination_address,
        spend_limit=invoice.quoted_asset_amount,
        status="ready",
    );
    invoice.status = "wallet_created";
    invoice.updated_at = datetime.now().isoformat();
    return wallet;
}

def:pub get_invoice_wallet(invoice_id: str) -> InvoiceWallet {
    invoice = find_invoice(invoice_id);
    return find_invoice_wallet(invoice);
}

def:pub retire_invoice_wallet(invoice_id: str) -> InvoiceWallet {
    invoice = find_invoice(invoice_id);
    wallet = find_invoice_wallet(invoice);
    wallet.status = "retired";
    wallet.retired_at = datetime.now().isoformat();
    return wallet;
}
