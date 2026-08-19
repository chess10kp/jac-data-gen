node Person {
    has name: str;
}

edge Friend {}

walker FindFriends {
    can find with Person entry {
        report here.name;
        visit [->:Friend:->];
    }
}
