# api.jac
import from datetime { datetime }

node User {
    has name: str;
    has email: str;
    has created_at: str;
}

# List all users
walker:pub list_users {
    can fetch with Root entry {
        users = [-->][?:User];
        report [{
            "id": jid(u),
            "name": u.name,
            "email": u.email
        } for u in users];
    }
}

# Get single user
walker:pub get_user {
    has user_id: str;

    can fetch with Root entry {
        for u in [-->][?:User] {
            if jid(u) == self.user_id {
                report {
                    "id": jid(u),
                    "name": u.name,
                    "email": u.email,
                    "created_at": u.created_at
                };
                return;
            }
        }
        report {"error": "Not found"};
    }
}

# Create user
walker:pub create_user {
    has name: str;
    has email: str;

    can create with Root entry {
        user = User(
            name=self.name,
            email=self.email,
            created_at=datetime.now().isoformat()
        );
        root ++> user;
        report {"id": jid(user), "name": user.name, "email": user.email};
    }
}

# Update user
walker:pub update_user {
    has user_id: str;
    has name: str = "";
    has email: str = "";

    can update with Root entry {
        for u in [-->][?:User] {
            if jid(u) == self.user_id {
                if self.name { u.name = self.name; }
                if self.email { u.email = self.email; }
                report {"id": jid(u), "name": u.name, "email": u.email};
                return;
            }
        }
        report {"error": "Not found"};
    }
}

# Delete user
walker:pub delete_user {
    has user_id: str;

    can remove with Root entry {
        for u in [-->][?:User] {
            if jid(u) == self.user_id {
                del u;
                report {"deleted": True};
                return;
            }
        }
        report {"error": "Not found"};
    }
}

# Health check
walker:pub health {
    can check with Root entry {
        report {"status": "ok", "timestamp": datetime.now().isoformat()};
    }
}
