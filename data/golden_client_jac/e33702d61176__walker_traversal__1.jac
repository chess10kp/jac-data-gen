import json;

walker save_state {
    can save with Root entry {
        data = {
            "users": [u.__dict__ for u in [-->][?:User]],
            "posts": [p.__dict__ for p in [-->][?:Post]]
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
                root ++> User(**u);
            }

            report {"loaded": True};
        } except FileNotFoundError {
            report {"loaded": False, "reason": "No saved state"};
        }
    }
}
