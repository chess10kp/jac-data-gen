# Server-only section
node User {
    has email: str;
}

# Single-statement form (no header, no braces)
sv import from .database { connect_db }
sv node SecretData { has value: str; }
