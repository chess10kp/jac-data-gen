node User {
    has name: str;
}

node Post {
    has content: str;
}

edge Authored {}

with entry {
    user = root ++> User(name="alice");
    user[0] +>:Authored:+> Post(content="hello world");

    # a user's posts: traverse outward along Authored
    posts = [user[0] ->:Authored:-> ];
    print(posts);
}
