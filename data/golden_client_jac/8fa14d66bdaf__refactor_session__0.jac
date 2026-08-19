walker FindFollowers {
    can find with User entry;
}

walker FindMutualFollows {
    can find with User entry;
}

impl FindFollowers.find { ... }
impl FindMutualFollows.find { ... }
