import from re { sub }

glob properties_db: list = [];
glob units_db: list = [];
glob tenants_db: list = [];

def normalize_phone(phone: str) -> str {
    if not phone { return ""; }
    cleaned = sub(r"[^\d+]", "", str(phone));
    if not cleaned.startswith("+") and len(cleaned) == 10 {
        cleaned = "+1" + cleaned;
    }
    return cleaned;
}

def:pub get_properties() -> dict {
    return {"properties": properties_db};
}

def:pub get_tenants() -> dict {
    return {"tenants": tenants_db};
}

def:pub add_property(prop: dict) -> dict {
    prop["id"] = "P-" + str(len(properties_db) + 1);
    properties_db.append(prop);
    return {"success": True, "property": prop};
}

def:pub add_tenant(tenant: dict) -> dict {
    raw_phone = str(tenant.get("phone_number", ""));
    tenant["id"] = "T-" + str(len(tenants_db) + 1);
    tenant["normalized_phone_number"] = normalize_phone(raw_phone);
    tenants_db.append(tenant);
    return {"success": True, "tenant": tenant};
}

def:pub match_phone(phone: str) -> dict {
    norm = normalize_phone(phone);
    for t in tenants_db {
        if str(t.get("normalized_phone_number")) == norm or str(t.get("phone_number")) == phone {
            prop_name = "Unknown Property";
            for p in properties_db {
                if str(p.get("id")) == str(t.get("property_id")) {
                    prop_name = str(p.get("property_name"));
                    break;
                }
            }
            return {
                "matched": True,
                "tenant_name": str(t.get("full_name")),
                "property_name": prop_name,
                "unit": str(t.get("unit_label", "?"))
            };
        }
    }
    return {"matched": False};
}

def:pub update_property(prop: dict) -> dict {
    for i in range(len(properties_db)) {
        if str(properties_db[i].get("id")) == str(prop.get("id")) {
            properties_db[i] = prop;
            return {"success": True, "property": prop};
        }
    }
    return {"success": False, "error": "Property not found"};
}

def:pub delete_property(prop_id: str) -> dict {
    for i in range(len(properties_db)) {
        if str(properties_db[i].get("id")) == str(prop_id) {
            properties_db.pop(i);
            # Also clean up associated tenants or let them orphan? Let's just pop prop
            return {"success": True};
        }
    }
    return {"success": False, "error": "Property not found"};
}

def:pub update_tenant(tenant: dict) -> dict {
    raw_phone = str(tenant.get("phone_number", ""));
    tenant["normalized_phone_number"] = normalize_phone(raw_phone);
    for i in range(len(tenants_db)) {
        if str(tenants_db[i].get("id")) == str(tenant.get("id")) {
            tenants_db[i] = tenant;
            return {"success": True, "tenant": tenant};
        }
    }
    return {"success": False, "error": "Tenant not found"};
}

def:pub delete_tenant(tenant_id: str) -> dict {
    for i in range(len(tenants_db)) {
        if str(tenants_db[i].get("id")) == str(tenant_id) {
            tenants_db.pop(i);
            return {"success": True};
        }
    }
    return {"success": False, "error": "Tenant not found"};
}
