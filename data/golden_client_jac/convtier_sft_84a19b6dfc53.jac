node Sniffer { has text: str; }
node Rule { has lang: str, token: str, weight: int; }

walker Sniff {
    has text: str = "", scores: dict = {}, best: str = "unknown";
    can start with Sniffer entry {
        self.text = here.text;
        visit [-->][?:Rule];
    }
    can score with Rule entry {
        if here.token in self.text {
            self.scores[here.lang] = self.scores.get(here.lang, 0) + here.weight;
        }
    }
    can judge with exit {
        best_score = 0;
        for lang in sorted(self.scores.keys()) {
            if self.scores[lang] > best_score {
                self.best = lang;
                best_score = self.scores[lang];
            }
        }
    }
}

def sniff_lang(spec: dict) -> str {
    sniffer = Sniffer(text=str(spec["text"]));
    for r in spec["rules"] {
        sniffer ++> Rule(lang=str(r["lang"]), token=str(r["token"]), weight=int(r["weight"]));
    }
    return (sniffer spawn Sniff()).best;
}

with entry {
    print(sniff_lang({'rules': [{'lang': 'python', 'token': 'def ', 'weight': 2}, {'lang': 'python', 'token': 'import ', 'weight': 1}, {'lang': 'javascript', 'token': 'function ', 'weight': 2}, {'lang': 'javascript', 'token': 'const ', 'weight': 1}], 'text': 'import os\\ndef main():\\n    pass'}));
}
