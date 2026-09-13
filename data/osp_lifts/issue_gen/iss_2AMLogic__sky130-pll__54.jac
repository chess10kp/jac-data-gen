# PROGRAM iss_2AMLogic__sky130-pll__54.jac

node Corner {
    has key: str;
    has process: str;
    has temp_c: int;
    has supply_v: str;
}

node Campaign {
    has name: str;
    has issue: int = 54;
    has timeout_s: int = 1800;
    has corners: list[Corner] = [];
}

edge Covers {}
edge DependsOn {}
edge References {}
edge Supersedes {}

obj CampaignIndex {
    has campaigns: list[Campaign] = [];
}

walker DependencyWalk {
    has claimed: dict[str, bool] = {};
    has found: list[Campaign] = [];

    can collect with Campaign entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here);
        print(here.name);
        for prerequisite in [here ->:DependsOn:->][?:Campaign] {
            visit :0: [prerequisite];
        }
    }
}

def new_campaign(name: str, issue: int = 54, timeout_s: int = 1800) -> Campaign {
    return Campaign(name=name, issue=issue, timeout_s=timeout_s);
}

def new_campaign_index() -> CampaignIndex {
    return CampaignIndex();
}

def register_campaign(index: CampaignIndex, campaign: Campaign) -> bool {
    for existing in index.campaigns {
        if existing.name == campaign.name {
            return False;
        }
    }
    index.campaigns.append(campaign);
    return True;
}

def find_campaign(index: CampaignIndex, name: str) -> Campaign | None {
    for campaign in index.campaigns {
        if campaign.name == name {
            return campaign;
        }
    }
    return None;
}

def add_dependency(campaign: Campaign, prerequisite: Campaign) {
    campaign +>:DependsOn:+> prerequisite;
}

def add_reference(campaign: Campaign, referenced: Campaign) {
    campaign +>:References:+> referenced;
}

def add_supersedes(newer: Campaign, previous: Campaign) {
    newer +>:Supersedes:+> previous;
}

def link_dependency(index: CampaignIndex, dependent_name: str, prerequisite_name: str) -> bool {
    dependent = find_campaign(index, dependent_name);
    prerequisite = find_campaign(index, prerequisite_name);
    if dependent == None {
        return False;
    }
    if prerequisite == None {
        return False;
    }
    add_dependency(dependent, prerequisite);
    return True;
}

def link_reference(index: CampaignIndex, campaign_name: str, referenced_name: str) -> bool {
    campaign = find_campaign(index, campaign_name);
    referenced = find_campaign(index, referenced_name);
    if campaign == None {
        return False;
    }
    if referenced == None {
        return False;
    }
    add_reference(campaign, referenced);
    return True;
}

def dependency_closure(index: CampaignIndex, name: str) -> list[str] {
    campaign = find_campaign(index, name);
    if campaign == None {
        return [];
    }
    w = campaign spawn DependencyWalk(claimed={});
    names: list[str] = [];
    for found_campaign in w.found {
        names.append(found_campaign.name);
    }
    return sorted(names);
}

def reference_names(campaign: Campaign) -> list[str] {
    names: list[str] = [];
    for referenced in [campaign ->:References:->][?:Campaign] {
        names.append(referenced.name);
    }
    return sorted(names);
}

def superseded_names(campaign: Campaign) -> list[str] {
    names: list[str] = [];
    for previous in [campaign ->:Supersedes:->][?:Campaign] {
        names.append(previous.name);
    }
    return sorted(names);
}

def add_pvt_grid(campaign: Campaign) -> list[str] {
    processes: list[str] = ["tt", "ss", "ff"];
    temperatures: list[int] = [-40, 27, 125];
    supplies: list[str] = ["1.62", "1.80", "1.98"];
    keys: list[str] = [];

    for process in processes {
        for temp_c in temperatures {
            for supply_v in supplies {
                key: str = process + "@" + str(temp_c) + "C/" + supply_v + "V";
                exists: bool = False;
                for old_corner in campaign.corners {
                    if old_corner.key == key {
                        exists = True;
                    }
                }
                if not exists {
                    corner = Corner(
                        key=key,
                        process=process,
                        temp_c=temp_c,
                        supply_v=supply_v
                    );
                    campaign +>:Covers:+> corner;
                    campaign.corners.append(corner);
                }
                keys.append(key);
            }
        }
    }
    return sorted(keys);
}
