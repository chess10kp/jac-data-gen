walker:pub get_user {
    has user_id: str;

    can fetch with Root entry {
        for user in [-->][?:User] {
            if user.id == self.user_id {
                report {
                    "id": user.id,
                    "name": user.name,
                    "email": user.email
                };
                return;
            }
        }
        report {"error": "User not found"};
    }
}
