node SecureRoom {
    has required_level: int;

    # 'visitor' refers to the walker visiting this node
    # 'self' refers to this node instance
    can check with Inspector entry {
        if visitor.clearance >= self.required_level {
            print("Access granted to " + visitor.name);
        }
    }
}

walker Inspector {
    has clearance: int;
    has name: str;

    # 'here' refers to the current node being visited
    # 'self' refers to this walker instance
    can inspect with SecureRoom entry {
        print(f"{self.name} inspecting room at {here}");
        print(f"Room requires level {here.required_level}");
    }

    can start with Root entry {
        # 'root' is always the graph root
        print(f"Starting from root: {root}");
        visit [-->];
    }
}
