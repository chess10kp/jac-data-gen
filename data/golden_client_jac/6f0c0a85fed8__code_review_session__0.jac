node SecureRoom {
    has required_level: int;

    can check with Inspector entry {
        if visitor.clearance >= self.required_level {
            print(f"Access granted to {visitor.name}");
        } else {
            print(f"Access denied for {visitor.name} (needs level {self.required_level})");
        }
    }
}

walker Inspector {
    has clearance: int;
    has name: str;

    can inspect with SecureRoom entry {
        print(f"{self.name} inspecting room at {here}");
        print(f"Room requires level {here.required_level}");
    }

    can start with Root entry {
        print(f"Starting from root: {root}");
        visit [-->];
    }
}

with entry {
    root ++> SecureRoom(required_level=3);
    root spawn Inspector(clearance=5, name="Ava");
}
