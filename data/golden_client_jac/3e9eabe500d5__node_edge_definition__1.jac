node Entity {
    has created_at: str;
}

node User(Entity) {
    has username: str;
    has email: str;
}
