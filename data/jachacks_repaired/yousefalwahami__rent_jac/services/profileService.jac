import from os { getenv }
import from dotenv { load_dotenv }

glob _: any = load_dotenv();

# In-memory profile store keyed by root node id — no graph nodes, no DB crashes
glob _profiles: dict = {};

walker get_profile {
    can read with Root entry {
        user_id = str(here.__jac__.id);
        profile = _profiles.get(user_id, {});
        report {
            "phone_number": profile.get("phone_number", getenv("TWILIO_TARGET_PHONE_NUMBER") or ""),
            "name": profile.get("name", getenv("OWNER_NAME") or ""),
            "email": profile.get("email", "")
        };
    }
}

walker update_profile {
    has phone_number: str = "";
    has name: str = "";
    has email: str = "";

    can write with Root entry {
        user_id = str(here.__jac__.id);
        existing = _profiles.get(user_id, {});
        existing["phone_number"] = self.phone_number if self.phone_number else existing.get("phone_number", "");
        existing["name"] = self.name if self.name else existing.get("name", "");
        existing["email"] = self.email if self.email else existing.get("email", "");
        _profiles[user_id] = existing;
        report {"success": True, "phone_number": existing["phone_number"], "name": existing["name"]};
    }
}
