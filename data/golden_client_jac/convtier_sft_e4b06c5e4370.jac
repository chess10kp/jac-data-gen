node Funnel {}
node Event { has stage: str; }

walker FunnelCount {
    has stages: list;
    has tally: dict = {}, result: list = [];
    can start with Funnel entry { visit [-->][?:Event]; }
    can count with Event entry {
        self.tally[here.stage] = self.tally.get(here.stage, 0) + 1;
    }
    can arrange with exit {
        for s in self.stages { self.result.append(self.tally.get(s, 0)); }
    }
}

def stage_funnel(spec: dict) -> list {
    funnel = Funnel();
    for ev in spec["events"] { funnel ++> Event(stage=str(ev)); }
    stages: list = [str(s) for s in spec["stages"]];
    return (funnel spawn FunnelCount(stages=stages)).result;
}

with entry {
    print(stage_funnel({'events': ['view', 'view', 'signup', 'view', 'purchase', 'signup'], 'stages': ['view', 'signup', 'purchase']}));
}
