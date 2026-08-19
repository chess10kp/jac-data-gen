import json;

node User {
    has id: str;
    has name: str;
    has email: str = "";
}

node Post {
    has title: str;
    has body: str = "";
}

walker save_state {
    can save with Root entry {
        data = {
            "users": [{"id": u.id, "name": u.name, "email": u.email} for u in [-->][?:User]],
            "posts": [{"title": p.title, "body": p.body} for p in [-->][?:Post]]
        };

        with open("state.json", "w") as f {
            json.dump(data, f);
        }

        report {"saved": True};
    }
}

walker load_state {
    can load with Root entry {
        try {
            with open("state.json", "r") as f {
                data = json.load(f);
            }

            for u in data["users"] {
                root ++> User(
                    id=str(u["id"]),
                    name=str(u["name"]),
                    email=str(u["email"])
                );
            }

            report {"loaded": True};
        } except FileNotFoundError {
            report {"loaded": False, "reason": "No saved state"};
        }
    }
}
