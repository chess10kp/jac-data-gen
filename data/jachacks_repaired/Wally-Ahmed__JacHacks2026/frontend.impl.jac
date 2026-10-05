impl app.go_landing {
    auth_error = "";
    if is_logged_in {
        route = "dashboard";
    } else {
        route = "landing";
    }
}

impl app.go_login {
    auth_error = "";
    route = "login";
}

impl app.go_signup {
    auth_error = "";
    route = "signup";
}

impl app.go_dashboard {
    auth_error = "";
    route = "dashboard";
}

impl app.sync_merchant_profile {
    merchants = await list_merchants();
    if len(merchants) > 0 {
        merchant = merchants[0];
        resolved_merchant_id = str(merchant.merchant_id);
        if not resolved_merchant_id.strip() {
            resolved_merchant_id = jid(merchant);
        }
        merchant_id = resolved_merchant_id;
        legal_name = merchant.legal_name;
        display_name = merchant.display_name;
        email = merchant.email;
        status = merchant.status;
        default_chain = merchant.default_chain;
        default_asset = merchant.default_asset;
        await sync_wallets(resolved_merchant_id);
        return resolved_merchant_id;
    } else {
        merchant_id = "";
        wallets = [];
        return "";
    }
}

impl app.ensure_merchant_profile {
    resolved_merchant_id = await sync_merchant_profile();
    if resolved_merchant_id {
        return resolved_merchant_id;
    }

    email_value = str(email).strip();
    legal_name_value = str(legal_name).strip();
    display_name_value = str(display_name).strip();
    fallback_name = "merchant";
    if email_value and "@" in email_value {
        fallback_name = email_value.split("@")[0];
    }

    if not email_value {
        email_value = fallback_name + "@local.invalid";
    }

    if not legal_name_value {
        legal_name_value = fallback_name;
    }
    if not display_name_value {
        display_name_value = legal_name_value;
    }

    merchant = await create_merchant(
        legal_name_value,
        email_value,
        display_name_value,
    );

    resolved_merchant_id = str(merchant.merchant_id);
    if not resolved_merchant_id.strip() {
        resolved_merchant_id = jid(merchant);
    }
    merchant_id = resolved_merchant_id;
    legal_name = merchant.legal_name;
    display_name = merchant.display_name;
    email = merchant.email;
    status = merchant.status;
    default_chain = merchant.default_chain;
    default_asset = merchant.default_asset;
    await sync_wallets(resolved_merchant_id);
    return resolved_merchant_id;
}

impl app.sync_wallets(merchant_ref: str = "") {
    resolved_merchant_id = str(merchant_ref).strip();
    if not resolved_merchant_id {
        resolved_merchant_id = str(merchant_id).strip();
    }
    if not resolved_merchant_id {
        wallets = [];
        return;
    }
    wallets = await list_merchant_wallets(resolved_merchant_id);
}

impl app.login_submit {
    auth_error = "";
    email_value = str(email).strip();
    password_value = str(password);
    success = await jacLogin(email_value, password_value);
    if not success {
        auth_error = "Invalid email or password.";
        return;
    }
    is_logged_in = True;
    await ensure_merchant_profile();
    route = "dashboard";
}

impl app.signup_submit {
    auth_error = "";
    legal_name_value = str(legal_name).strip();
    email_value = str(email).strip();
    display_name_value = str(display_name).strip();
    password_value = str(password);
    if not legal_name_value or not email_value {
        auth_error = "Legal name and email are required.";
        return;
    }
    if not password_value.strip() {
        auth_error = "Password is required.";
        return;
    }
    signup_result = await jacSignup(email_value, password_value);
    if not signup_result["success"] {
        auth_error = signup_result["error"] or "Signup failed.";
        return;
    }
    login_success = await jacLogin(email_value, password_value);
    if not login_success {
        auth_error = "Account created, but login failed. Please log in manually.";
        route = "login";
        return;
    }
    merchant = await create_merchant(
        legal_name_value,
        email_value,
        display_name_value,
    );
    resolved_merchant_id = str(merchant.merchant_id);
    if not resolved_merchant_id.strip() {
        resolved_merchant_id = jid(merchant);
    }
    merchant_id = resolved_merchant_id;
    legal_name = merchant.legal_name;
    display_name = merchant.display_name;
    email = merchant.email;
    is_logged_in = True;
    await sync_wallets(resolved_merchant_id);
    route = "dashboard";
}

impl app.remove_wallet(wallet_id: str) {
    auth_error = "";
    resolved_merchant_id = str(merchant_id).strip();
    if not resolved_merchant_id {
        resolved_merchant_id = await sync_merchant_profile();
    }
    if not resolved_merchant_id {
        auth_error = "No merchant profile was found for this session.";
        return;
    }
    await delete_merchant_wallet(
        resolved_merchant_id,
        wallet_id,
    );
    await sync_wallets(resolved_merchant_id);
}

impl app.logout {
    jacLogout();
    is_logged_in = False;
    merchant_id = "";
    auth_error = "";
    password = "";
    wallets = [];
    route = "landing";
}
