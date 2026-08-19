node Feed {}
node User { has name: str; }
node Post { has author: str; has likes: int; }

walker TopScan {
    has best: str = "";
    has bl: int = 0;
    has seen: bool = False;
    can start with Feed entry { visit [-->][?:User]; }
    can seek with User entry { visit [-->][?:Post]; }
    can judge with Post entry {
        if not self.seen or here.likes > self.bl or (here.likes == self.bl and here.author < self.best) {
            self.best = here.author; self.bl = here.likes; self.seen = True;
        }
    }
}

def author_of_top_post(spec: dict) -> str {
    posts: list = list(spec["posts"]);
    if len(posts) == 0 { return ""; }
    feed = Feed();
    unodes: dict = {};
    for p in posts {
        a: str = str(p["author"]);
        if a not in unodes { u = User(name=a); unodes[a] = u; feed ++> u; }
        unodes[a] ++> Post(author=a, likes=int(p["likes"]));
    }
    return (feed spawn TopScan()).best;
}

with entry {
    print(author_of_top_post({'posts': [{'author': 'bob', 'likes': 7}, {'author': 'ana', 'likes': 9}, {'author': 'bob', 'likes': 4}]}));
}
