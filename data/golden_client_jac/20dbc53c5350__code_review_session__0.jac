node Resource {
    has name: str;
}

walker :priv make_private {
    can revoke with Resource entry {
        # `here` is the concrete node the walker is on -- not a loose placeholder.
        perm_revoke(here);
        report {"resource": here.name, "public_access": "revoked"};
    }
}

with entry {
    res = (root ++> Resource(name="quarterly-report"))[0];
    root spawn make_private();
}
