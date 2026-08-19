sv node User {
    has email: str;
}

sv import from .database { connect_db }
sv node SecretData { has value: str; }
