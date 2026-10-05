import from datetime { datetime }
import os;
import from json { loads }
import from dotenv { load_dotenv }
import from base64 { b64encode }
import ssl;
import certifi;
import from urllib.parse { urlencode }
import from urllib.request { Request, urlopen }
import from nodes.CheckoutSession { CheckoutSession }
import from nodes.PaymentEvent { PaymentEvent }
import from nodes.Invoice { Invoice }
import from nodes.MerchantWallet { MerchantWallet }
import from services.invoice { find_invoice }
import from services.invoice { create_invoice }
import from services.merchant { find_merchant_wallet, find_wallet_merchant, find_merchant, find_public_wallet_record, find_public_wallet_for_merchant }

def find_checkout_for_invoice(invoice: Invoice) -> CheckoutSession {
    for checkout in [invoice-->][?:CheckoutSession] {
        return checkout;
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

def env_optional(name: str, fallback: str = "") -> str {
    load_dotenv();
    value = os.getenv(name);
    if not value {
        return fallback;
    }
    return value;
}

def amount_to_cents(amount: float) -> int {
    return int(round(amount * 100));
}

def stripe_checkout_urls() -> dict {
    load_dotenv();
    success_url = env_optional("STRIPE_SUCCESS_URL");
    cancel_url = env_optional("STRIPE_CANCEL_URL");
    app_base = env_optional("APP_BASE_URL", "http://localhost:8000");

    if not success_url {
        success_url = app_base + "/payment/success?session_id={CHECKOUT_SESSION_ID}";
    }
    if not cancel_url {
        cancel_url = app_base + "/payment/cancel";
    }

    return {
        "success_url": success_url,
        "cancel_url": cancel_url,
    };
}

def stripe_create_hosted_checkout(invoice: Invoice) -> dict {
    secret_key = env_required("STRIPE_SECRET_KEY");
    urls = stripe_checkout_urls();
    amount_cents = amount_to_cents(invoice.fiat_amount);
    if amount_cents <= 0 {
        raise Exception("Invoice amount must be greater than zero.");
    }

    item_name = "UNIBANK payment";
    if invoice.reference {
        item_name = "UNIBANK payment " + invoice.reference;
    }
    item_description = invoice.description;
    if not item_description {
        item_description = "Card payment for " + invoice.invoice_id;
    }

    payload = urlencode({
        "mode": "payment",
        "success_url": urls["success_url"],
        "cancel_url": urls["cancel_url"],
        "client_reference_id": invoice.invoice_id,
        "metadata[invoice_id]": invoice.invoice_id,
        "metadata[merchant_id]": invoice.merchant_id,
        "line_items[0][quantity]": "1",
        "line_items[0][price_data][currency]": invoice.fiat_currency.lower(),
        "line_items[0][price_data][unit_amount]": str(amount_cents),
        "line_items[0][price_data][product_data][name]": item_name,
        "line_items[0][price_data][product_data][description]": item_description,
    }).encode("utf-8");

    auth_bytes = b64encode((secret_key + ":").encode("utf-8")).decode("utf-8");
    request = Request(
        "https://api.stripe.com/v1/checkout/sessions",
        data=payload,
        headers={
            "Authorization": "Basic " + auth_bytes,
            "Content-Type": "application/x-www-form-urlencoded",
        },
        method="POST",
    );

    ssl_context = ssl.create_default_context(cafile=certifi.where());
    response = urlopen(request, context=ssl_context);
    return loads(response.read().decode("utf-8"));
}

def create_public_invoice(merchant_id: str, wallet_record: dict, reference: str, dollar_value: float, description: str = "") -> Invoice {
    return root ++> Invoice(
        invoice_id="invoice_" + str(len([root-->][?:Invoice]) + 1),
        merchant_id=merchant_id,
        reference=reference,
        description=description,
        fiat_amount=dollar_value,
        fiat_currency="USD",
        target_chain=wallet_record["chain"],
        quoted_asset_amount=dollar_value,
        destination_address=wallet_record["address"],
        status="created",
    );
}

def:pub create_checkout_session(invoice_id: str) -> CheckoutSession {
    invoice = find_invoice(invoice_id);
    existing = find_checkout_for_invoice(invoice);
    if existing {
        return existing;
    }
    stripe_session = stripe_create_hosted_checkout(invoice);
    checkout = invoice ++> CheckoutSession(
        checkout_id="checkout_" + invoice.invoice_id,
        provider_session_id=stripe_session["id"],
        provider_payment_intent_id=stripe_session["payment_intent"] or "",
        hosted_url=stripe_session["url"],
        amount_total=invoice.fiat_amount,
        currency=invoice.fiat_currency,
        status="open",
    );
    invoice.checkout_url = checkout.hosted_url;
    invoice.status = "checkout_created";
    invoice.updated_at = datetime.now().isoformat();
    return checkout;
}

def:pub create_checkout_for_wallet(wallet_id: str, dollar_value: float, reference: str = "", description: str = "") -> CheckoutSession {
    wallet_record = find_public_wallet_record(wallet_id);
    if not wallet_record {
        raise Exception("Merchant wallet not found.");
    }
    if wallet_record["status"] != "active" {
        raise Exception("Merchant wallet is not active.");
    }

    invoice_reference = reference;
    if not invoice_reference {
        invoice_reference = "public_" + wallet_record["wallet_id"] + "_" + str(len([root-->][?:Invoice]) + 1);
    }
    invoice_description = description;
    if not invoice_description {
        invoice_description = "Public checkout for wallet " + wallet_record["wallet_id"];
    }

    invoice = create_public_invoice(
        merchant_id=wallet_record["merchant_id"],
        wallet_record=wallet_record,
        reference=invoice_reference,
        description=invoice_description,
        dollar_value=dollar_value,
    );
    return create_checkout_session(invoice.invoice_id);
}

def:pub create_card_payment(wallet_id: str, amount_usd: float, reference: str = "", description: str = "") -> dict {
    checkout = create_checkout_for_wallet(
        wallet_id=wallet_id,
        dollar_value=amount_usd,
        reference=reference,
        description=description,
    );
    return {
        "wallet_id": wallet_id,
        "amount_usd": amount_usd,
        "checkout_id": checkout.checkout_id,
        "checkout_url": checkout.hosted_url,
        "provider": checkout.provider,
        "provider_session_id": checkout.provider_session_id,
        "status": checkout.status,
    };
}

def:pub create_card_payment_for_merchant(merchant_id: str, dollar_value: float, reference: str = "", description: str = "") -> dict {
    wallet_record = find_public_wallet_for_merchant(merchant_id);
    if not wallet_record {
        raise Exception("Merchant not found.");
    }

    invoice_reference = reference;
    if not invoice_reference {
        invoice_reference = "merchant_" + merchant_id + "_" + str(len([root-->][?:Invoice]) + 1);
    }
    invoice_description = description;
    if not invoice_description {
        invoice_description = "Card payment for merchant " + wallet_record["display_name"];
    }

    checkout = create_checkout_for_wallet(
        wallet_id=wallet_record["wallet_id"],
        dollar_value=dollar_value,
        reference=invoice_reference,
        description=invoice_description,
    );

    return {
        "merchant_id": merchant_id,
        "wallet_id": wallet_record["wallet_id"],
        "amount_usd": dollar_value,
        "checkout_id": checkout.checkout_id,
        "checkout_url": checkout.hosted_url,
        "provider": checkout.provider,
        "provider_session_id": checkout.provider_session_id,
        "status": checkout.status,
    };
}

def:pub get_checkout(invoice_id: str) -> CheckoutSession {
    invoice = find_invoice(invoice_id);
    return find_checkout_for_invoice(invoice);
}

def:pub stripe_webhook(event_type: str, invoice_id: str, provider_event_id: str) -> PaymentEvent {
    invoice = find_invoice(invoice_id);
    event = invoice ++> PaymentEvent(
        event_id="event_" + str(len([invoice-->][?:PaymentEvent]) + 1),
        provider_event_id=provider_event_id,
        event_type=event_type,
        payment_status="succeeded" if event_type == "payment_intent.succeeded" else "failed",
    );
    if event_type == "payment_intent.succeeded" {
        invoice.status = "payment_succeeded";
    } else {
        invoice.status = "payment_failed";
    }
    invoice.updated_at = datetime.now().isoformat();
    checkout = find_checkout_for_invoice(invoice);
    if checkout {
        checkout.status = "completed" if event_type == "payment_intent.succeeded" else "failed";
        checkout.updated_at = datetime.now().isoformat();
    }
    return event;
}

def:pub mark_payment_succeeded(invoice_id: str) -> Invoice {
    stripe_webhook("payment_intent.succeeded", invoice_id, "evt_test_success_" + invoice_id);
    return find_invoice(invoice_id);
}

def:pub mark_payment_failed(invoice_id: str) -> Invoice {
    stripe_webhook("payment_intent.payment_failed", invoice_id, "evt_test_failed_" + invoice_id);
    return find_invoice(invoice_id);
}
