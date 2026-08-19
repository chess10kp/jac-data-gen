obj Signup {
    has username: str = "";
    has email: str = "";
    has age: int = 0;

    def errors -> list {
        found = [];
        if len(self.username) < 3 {
            found.append("username too short");
        }
        if "@" not in self.email {
            found.append("invalid email");
        }
        if self.age < 13 or self.age > 120 {
            found.append("age out of range");
        }
        return found;
    }
}

def validate_signup(rec: dict) -> str {
    s = Signup(
        username=rec.get("username", ""),
        email=rec.get("email", ""),
        age=rec.get("age", 0)
    );
    errs = s.errors();
    return "; ".join(errs) if errs else "ok";
}

with entry {
    print(validate_signup({'username': 'carol', 'email': 'c@x.io', 'age': 30}));
}
