walker _authenticate {
    has headers: dict;

    can check with `root entry {
        token = self.headers.get("Authorization", "");

        if not token.startswith("Bearer ") {
            report {"error": "Unauthorized", "status": 401};
            return;
        }

        raw = token[7:];
        if not is_valid_token(raw) {
            report {"error": "Invalid token", "status": 401};
            return;
        }

        report {"authenticated": True};
    }
}
