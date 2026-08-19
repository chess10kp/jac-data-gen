node User { has name: str; }
node Channel { has name: str; }
edge Member {}

walker MemberCount {
    has count: int = 0;
    can scan with Channel entry { self.count = len([<-:Member:<-][?:User]); }
}

def channel_member_count(spec: dict) -> int {
    unodes: dict = {};
    for nm in list(spec["users"]) { unodes[nm] = User(name=str(nm)); }
    cnodes: dict = {};
    for cn in list(spec["channels"]) { cnodes[cn] = Channel(name=str(cn)); }
    for m in list(spec["members"]) {
        if m[0] in unodes and m[1] in cnodes { unodes[m[0]] +>:Member:+> cnodes[m[1]]; }
    }
    target: str = str(spec["channel"]);
    if target not in cnodes { return -1; }
    return (cnodes[target] spawn MemberCount()).count;
}

with entry {
    print(channel_member_count({'users': ['ava', 'ben', 'cleo'], 'channels': ['general', 'dev'], 'members': [['ava', 'general'], ['ben', 'general'], ['cleo', 'dev']], 'channel': 'general'}));
}
