node Person {
    has name: str;
}

walker FriendReporter {
    can report_friend with Person entry {
        print(f"{here.name} is a friend");
    }
}
