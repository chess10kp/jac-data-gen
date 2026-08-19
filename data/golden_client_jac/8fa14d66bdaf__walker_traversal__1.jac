node User {
    has username: str;
    has bio: str = "";
}

edge Follows {
    has since: str;
}

walker FindFollowers {
    can find with User entry {
        # Find all users who follow this user
        followers = [<-:Follows:<-];
        for follower in followers {
            report follower;
        }
    }
}

walker FindMutualFollows {
    can find with User entry {
        following = [here ->:Follows:->];
        followers = [here <-:Follows:<-];

        for user in following {
            if user in followers {
                report user;  # Mutual follow!
            }
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

    # Alice follows Bob, Bob follows Alice (mutual)
    alice +>: Follows(since="2024") :+> bob;
    bob +>: Follows(since="2024") :+> alice;

    # Carol follows Alice
    carol +>: Follows(since="2024") :+> alice;

    # Find Alice's followers
    result = alice spawn FindFollowers();
    print("Alice's followers:");
    for user in result.reports {
        print(f"  - {user.username}");
    }

    # Find Alice's mutual follows
    result = alice spawn FindMutualFollows();
    print("Alice's mutual follows:");
    for user in result.reports {
        print(f"  - {user.username}");
    }
}
