node User { has name: str; }

walker:priv GetUsers {
    can get with `root entry {
        users = [-->][?:User];
        report users;
    }
}
