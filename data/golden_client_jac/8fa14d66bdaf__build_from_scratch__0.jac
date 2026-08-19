node User {
    has username: str;
    has bio: str = "";
}

edge Follows {
    has since: str;
}

walker FindFollowers {
    can find with User entry {
        followers = [<-:Follows:<-];
        for follower in followers {
            report follower;
        }
    }
}
