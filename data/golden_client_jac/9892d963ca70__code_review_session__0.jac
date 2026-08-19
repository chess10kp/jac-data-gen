import from datetime { datetime }

node User {
    has name: str;
    has email: str;
    has created_at: str;
}

def find_user(user_id: str) -> User | None {
    for u in [root -->][?:User] {
        if jid(u) == user_id { return u; }
    }
    return None;
}

walker:pub list_users {
    can fetch with Root entry {
        users = [root -->][?:User];
        report [{"id": jid(u), "name": u.name, "email": u.email} for u in users];
    }
}

walker:pub get_user {
    has user_id: str;
    can fetch with Root entry {
        u = find_user(self.user_id);
        if u is None { report {"error": "Not found"}; return; }
        report {"id": jid(u), "name": u.name, "email": u.email, "created_at": u.created_at};
    }
}

walker:pub create_user {
    has name: str;
    has email: str;
    can create with Root entry {
        user = User(name=self.name, email=self.email, created_at=datetime.now().isoformat());
        root ++> user;
        report {"id": jid(user), "name": user.name, "email": user.email};
    }
}

walker:pub update_user {
    has user_id: str;
    has name: str = "";
    has email: str = "";
    can update with Root entry {
        u = find_user(self.user_id);
        if u is None { report {"error": "Not found"}; return; }
        if self.name { u.name = self.name; }
        if self.email { u.email = self.email; }
        report {"id": jid(u), "name": u.name, "email": u.email};
    }
}

walker:pub delete_user {
    has user_id: str;
    can remove with Root entry {
        u = find_user(self.user_id);
        if u is None { report {"error": "Not found"}; return; }
        del u;
        report {"deleted": True};
    }
}

walker:pub health {
    can check with Root entry {
        report {"status": "ok", "timestamp": datetime.now().isoformat()};
    }
}
