node User {
    has username: str;
    has bio: str = "";
}

edge Follows {
    has since: str;
}

walker FindFollowers {
    can find with User entry;
}

walker FindMutualFollows {
    can find with User entry;
}

impl FindFollowers.find {
    followers = [<-:Follows:<-];
    for follower in followers {
        report follower;
    }
}

impl FindMutualFollows.find {
    following = [here ->:Follows:->];
    followers = [here <-:Follows:<-];

    for user in following {
        if user in followers {
            report user;
        }
    }
}

with entry {
    alice = User(username="alice");
    bob = User(username="bob");
    carol = User(username="carol");

    root ++> alice;
    root ++> bob;
    root ++> carol;

    alice +>: Follows(since="2024") :+> bob;
    bob +>: Follows(since="2024") :+> alice;
    carol +>: Follows(since="2024") :+> alice;

    followers_res = alice spawn FindFollowers();
    print("Alice's followers:");
    for user in followers_res.reports {
        print(f"  - {user.username}");
    }

    mutual_res = alice spawn FindMutualFollows();
    print("Alice's mutual follows:");
    for user in mutual_res.reports {
        print(f"  - {user.username}");
    }
}
