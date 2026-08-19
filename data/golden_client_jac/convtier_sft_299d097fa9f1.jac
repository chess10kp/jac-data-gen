node Hub {}
node User { has name: str; }
edge Follow {}

walker Influencer {
    has best_name: str = "";
    has best_fans: int = -1;
    can fan with Hub entry { visit [-->][?:User]; }
    can judge with User entry {
        fans: int = len([<-:Follow:<-][?:User]);
        if fans > self.best_fans or (fans == self.best_fans and here.name < self.best_name) {
            self.best_fans = fans;
            self.best_name = here.name;
        }
    }
}

def top_influencer(spec: dict) -> str {
    names: list = sorted(set(list(spec["users"])));
    if not names { return ""; }
    hub = Hub();
    unodes: dict = {};
    for nm in names {
        unodes[nm] = User(name=str(nm));
        hub ++> unodes[nm];
    }
    for f in list(spec["follows"]) {
        if f[0] in unodes and f[1] in unodes { unodes[f[0]] +>:Follow:+> unodes[f[1]]; }
    }
    return (hub spawn Influencer()).best_name;
}

with entry {
    print(top_influencer({'users': ['ava', 'ben', 'cleo', 'dan'], 'follows': [['ava', 'cleo'], ['ben', 'cleo'], ['dan', 'cleo'], ['cleo', 'ava']]}));
}
