node User { has name: str; }
node Channel { has name: str; }
node Post {}
edge Member {}
edge ChannelPost {}

walker PulseScan {
    has members: int = 0;
    has posts: int = 0;
    can scan with Channel entry {
        self.members = len([<-:Member:<-][?:User]);
        visit [->:ChannelPost:->][?:Post];
    }
    can tally with Post entry { self.posts += 1; }
}

def channel_pulse(spec: dict) -> str {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    cnodes: dict = {};
    for cn in sorted(set(list(spec["channels"]))) { cnodes[cn] = Channel(name=str(cn)); }
    for m in list(spec["members"]) {
        if m[0] in unodes and m[1] in cnodes { unodes[m[0]] +>:Member:+> cnodes[m[1]]; }
    }
    for p in list(spec["posts"]) {
        if p["channel"] in cnodes { cnodes[p["channel"]] +>:ChannelPost:+> Post(); }
    }
    parts: list = [];
    for cn in sorted(cnodes.keys()) {
        w = cnodes[cn] spawn PulseScan();
        parts.append(cn + "=" + str(w.members) + "/" + str(w.posts));
    }
    return ",".join(parts);
}

with entry {
    print(channel_pulse({'users': ['ava', 'ben', 'cleo'], 'channels': ['general', 'dev'], 'members': [['ava', 'general'], ['ben', 'general'], ['cleo', 'dev']], 'posts': [{'id': 'p1', 'channel': 'general'}, {'id': 'p2', 'channel': 'dev'}, {'id': 'p3', 'channel': 'dev'}]}));
}
