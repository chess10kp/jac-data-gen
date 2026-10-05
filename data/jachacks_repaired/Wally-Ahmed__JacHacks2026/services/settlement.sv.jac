import from datetime { datetime }
import os;
import from uuid { uuid4 }
import from dotenv { load_dotenv }
import from json { loads }
import from subprocess { run }
import from nodes.TreasuryLot { TreasuryLot }
import from nodes.Payout { Payout }
import from nodes.Invoice { Invoice }
import from nodes.InvoiceWallet { InvoiceWallet }
import from services.invoice { find_invoice }
import from services.wallets { create_invoice_wallet, find_invoice_wallet }

def get_or_create_treasury_lot() -> TreasuryLot {
    for lot in [root-->][?:TreasuryLot] {
        return lot;
    }
    return root ++> TreasuryLot(
        treasury_lot_id="treasury_lot_1",
        amount=100000.0,
        available_amount=100000.0,
        reserved_amount=0.0,
        status="available",
    );
}

def find_payout(invoice: Invoice) -> Payout {
    for payout in [invoice-->][?:Payout] {
        return payout;
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

def:pub reserve_treasury(invoice_id: str) -> TreasuryLot {
    invoice = find_invoice(invoice_id);
    lot = get_or_create_treasury_lot();
    lot.reserved_amount = lot.reserved_amount + invoice.quoted_asset_amount;
    lot.available_amount = lot.available_amount - invoice.quoted_asset_amount;
    lot.status = "reserved";
    invoice.status = "funding_pending";
    invoice.updated_at = datetime.now().isoformat();
    return lot;
}

def:pub fund_invoice_wallet(invoice_id: str) -> InvoiceWallet {
    invoice = find_invoice(invoice_id);
    wallet = find_invoice_wallet(invoice);
    if not wallet {
        wallet = create_invoice_wallet(invoice_id);
    }
    wallet.status = "funded";
    invoice.status = "funded";
    invoice.updated_at = datetime.now().isoformat();
    return wallet;
}

def:pub create_payout(invoice_id: str) -> Payout {
    invoice = find_invoice(invoice_id);
    existing = find_payout(invoice);
    if existing {
        return existing;
    }
    payout = invoice ++> Payout(
        payout_id="payout_" + invoice.invoice_id,
        invoice_id=invoice.invoice_id,
        amount=invoice.quoted_asset_amount,
        destination_address=invoice.destination_address,
        status="pending",
    );
    invoice.status = "payout_pending";
    invoice.updated_at = datetime.now().isoformat();
    return payout;
}

def:pub broadcast_payout(invoice_id: str) -> Payout {
    invoice = find_invoice(invoice_id);
    payout = find_payout(invoice);
    if not payout {
        payout = create_payout(invoice_id);
    }
    payout.status = "broadcast";
    payout.tx_hash = "0xFILL_ME_TX_HASH_" + invoice.invoice_id;
    payout.broadcast_at = datetime.now().isoformat();
    payout.updated_at = payout.broadcast_at;
    invoice.status = "payout_broadcast";
    invoice.updated_at = payout.broadcast_at;
    return payout;
}

def:pub confirm_payout(invoice_id: str, tx_hash: str = "") -> Payout {
    invoice = find_invoice(invoice_id);
    payout = find_payout(invoice);
    if not payout {
        payout = broadcast_payout(invoice_id);
    }
    payout.status = "confirmed";
    if tx_hash {
        payout.tx_hash = tx_hash;
    }
    payout.confirmed_at = datetime.now().isoformat();
    payout.updated_at = payout.confirmed_at;
    invoice.status = "completed";
    invoice.updated_at = payout.confirmed_at;
    return payout;
}

def:pub retry_payout(payout_id: str) -> Payout {
    for invoice in [root-->][?:Invoice] {
        for payout in [invoice-->][?:Payout] {
            if payout.payout_id == payout_id or jid(payout) == payout_id {
                payout.status = "pending";
                payout.failure_reason = "";
                payout.updated_at = datetime.now().isoformat();
                invoice.status = "payout_pending";
                invoice.updated_at = payout.updated_at;
                return payout;
            }
        }
    }
}

def:pub get_failed_payouts() -> list[Payout] {
    failed: list[Payout] = [];
    for payout in [root-->][?:Payout] {
        if payout.status == "failed" {
            failed.append(payout);
        }
    }
    return failed;
}

def:pub send_usdc(destination: str, amount: float) -> dict {
    source_wallet_address = env_required("PLACEHOLDER_SOURCE_ADDRESS");
    source_chain = os.getenv("PLACEHOLDER_SOURCE_BLOCKCHAIN", os.getenv("CIRCLE_BLOCKCHAIN", "BASE-SEPOLIA"));
    source_asset = os.getenv("PLACEHOLDER_SOURCE_ASSET", "USDC");

    if not destination {
        raise Exception("Destination address is required.");
    }

    result = run(
        [
            "node",
            "scripts/circle-send-usdc.mjs",
            destination,
            str(amount),
        ],
        cwd=os.getcwd(),
        capture_output=True,
        text=True,
    );
    if result.returncode != 0 {
        raise Exception("Circle send failed: " + result.stderr);
    }
    tx_data = loads(result.stdout);
    now = datetime.now().isoformat();
    tx_hash = tx_data["tx_hash"];
    payout_status = "broadcast";
    if tx_data["state"] {
        payout_status = str(tx_data["state"]).lower();
    }

    payout = root ++> Payout(
        payout_id="manual_payout_" + str(uuid4()),
        invoice_id="manual",
        asset=source_asset,
        amount=amount,
        destination_address=destination,
        tx_hash=tx_hash,
        status=payout_status,
        broadcast_at=now,
        updated_at=now,
    );

    return {
        "source_wallet_address": tx_data["source_wallet_address"] or source_wallet_address,
        "source_chain": source_chain,
        "asset": source_asset,
        "destination": destination,
        "amount": amount,
        "tx_hash": tx_hash,
        "transaction_id": tx_data["transaction_id"],
        "status": payout_status,
        "payout_id": payout.payout_id,
        "note": "Real Circle transaction request created from placeholder source wallet env vars.",
    };
}
