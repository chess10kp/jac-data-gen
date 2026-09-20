# openai/codex#22275 — symlinked skill packages register nested internal SKILL.md files.

node Dir {
  has cid: str;
  has name: str;
  has is_symlink: bool = False;
}

node SkillMd {
  has cid: str;
  has skill_name: str;
  has blurb: str;
}

edge Child {}
edge Link {}

walker DeepCollect {
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];
  has booted: bool = False;

  can walk_dir with Dir entry {
    if not self.booted {
      self.booted = True;
      print("deep_collect", here.cid);
    }
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    for doc in [here ->:Child:->][?:SkillMd] {
      self.found.append(doc.skill_name);
    }
    kids: list[Dir] = [];
    for ch in [here ->:Child:->][?:Dir] {
      kids.append(ch);
    }
    for ch in kids {
      visit :0: ch;
    }
    for tgt in [here ->:Link:->][?:Dir] {
      visit :0: tgt;
    }
  }
}

walker InstalledCollect {
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];
  has booted: bool = False;

  can scan_root with Dir entry {
    if not self.booted {
      self.booted = True;
      print("installed_collect", here.cid);
    }
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    if here.cid != "skills" {
      disengage;
    }
    for child_dir in [here ->:Child:->][?:Dir] {
      for doc in [child_dir ->:Child:->][?:SkillMd] {
        self.found.append(doc.skill_name);
      }
      link_targets: list[Dir] = [];
      for tgt in [child_dir ->:Link:->][?:Dir] {
        link_targets.append(tgt);
      }
      for tgt in link_targets {
        for doc in [tgt ->:Child:->][?:SkillMd] {
          self.found.append(doc.skill_name);
        }
      }
    }
  }
}

walker FindSkillDoc {
  has claimed: dict[str, bool] = {};
  has target_cid: str;
  has policy: str;
  has hit: str = "";
  has booted: bool = False;

  can seek_dir with Dir entry {
    if not self.booted {
      self.booted = True;
      print("find_doc", self.target_cid, self.policy);
    }
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    for doc in [here ->:Child:->][?:SkillMd] {
      if doc.cid == self.target_cid {
        self.hit = doc.skill_name;
      }
    }
    if self.policy == "installed_only" and here.cid != "skills" {
      kids: list[Dir] = [];
      for ch in [here ->:Child:->][?:Dir] {
        kids.append(ch);
      }
      for ch in kids {
        if ch.is_symlink {
          skip;
        }
      }
      disengage;
    }
    next_dirs: list[Dir] = [];
    for ch in [here ->:Child:->][?:Dir] {
      next_dirs.append(ch);
    }
    for ch in next_dirs {
      visit ch;
    }
    for tgt in [here ->:Link:->][?:Dir] {
      visit tgt;
    }
  }
}

def build_skill_tree -> Dir {
  skills = Dir(cid="skills", name="skills");
  root ++> skills;

  plain = Dir(cid="plain-skill", name="plain-skill");
  skills +>:Child:+> plain;
  plain_doc = SkillMd(cid="plain-doc", skill_name="plain-skill", blurb="direct child");
  plain +>:Child:+> plain_doc;

  toolkit_link = Dir(cid="workflow-toolkit", name="workflow-toolkit", is_symlink=True);
  skills +>:Child:+> toolkit_link;

  tk_root = Dir(cid="tk-root", name="workflow-toolkit");
  root ++> tk_root;
  toolkit_link +>:Link:+> tk_root;

  tk_doc = SkillMd(cid="tk-doc", skill_name="workflow-toolkit", blurb="intended top-level skill");
  tk_root +>:Child:+> tk_doc;

  runtime = Dir(cid="runtime", name="runtime-sources");
  tk_root +>:Child:+> runtime;

  app_branch = Dir(cid="app-branch", name="app-workflow");
  runtime +>:Child:+> app_branch;
  app_log = Dir(cid="app-log-dir", name="apply-log");
  app_branch +>:Child:+> app_log;
  app_doc = SkillMd(cid="app-apply-doc", skill_name="apply-log", blurb="internal app workflow source");
  app_log +>:Child:+> app_doc;

  write_branch = Dir(cid="write-branch", name="writing-workflow");
  runtime +>:Child:+> write_branch;
  write_log = Dir(cid="write-log-dir", name="apply-log");
  write_branch +>:Child:+> write_log;
  write_doc = SkillMd(cid="write-apply-doc", skill_name="apply-log", blurb="internal writing workflow source");
  write_log +>:Child:+> write_doc;

  hub_a = Dir(cid="hub-a", name="hub-a");
  skills +>:Child:+> hub_a;
  hub_b = Dir(cid="hub-b", name="hub-b");
  skills +>:Child:+> hub_b;

  shared = Dir(cid="shared-target", name="shared-target");
  root ++> shared;
  hub_a +>:Child:+> shared;
  hub_b +>:Link:+> shared;

  shared_doc = SkillMd(cid="shared-doc", skill_name="once-skill", blurb="diamond revisit probe");
  shared +>:Child:+> shared_doc;

  loop_left = Dir(cid="loop-left", name="loop-left");
  loop_right = Dir(cid="loop-right", name="loop-right");
  root ++> loop_left;
  root ++> loop_right;
  loop_left +>:Link:+> loop_right;
  loop_right +>:Link:+> loop_left;
  loop_marker = SkillMd(cid="loop-doc", skill_name="loop-marker", blurb="cycle guard");
  loop_left +>:Child:+> loop_marker;

  return skills;
}

def discover_skill_names(skills_root: Dir, policy: str) -> list[str] {
  names: list[str] = [];
  if policy == "deep" {
    w = skills_root spawn DeepCollect(claimed={});
    names = w.found;
    print("discover_deep", len(names));
  } elif policy == "installed_only" {
    w = skills_root spawn InstalledCollect(claimed={});
    names = w.found;
    print("discover_installed", len(names));
  } else {
    names = [];
    print("discover_unknown", 0);
  }
  return sorted(names);
}

def duplicate_name_count(names: list[str]) -> int {
  tally: dict[str, int] = {};
  for n in names {
    if n in tally {
      tally[n] = tally[n] + 1;
    } else {
      tally[n] = 1;
    }
  }
  dups = 0;
  for k in tally {
    if tally[k] > 1 {
      dups = dups + 1;
    }
  }
  print("duplicate_name_count", dups);
  return dups;
}

def skill_doc_name(skills_root: Dir, doc_cid: str, policy: str) -> str {
  if doc_cid == "" {
    print("skill_doc_name_missing", doc_cid);
    return "";
  }
  w = skills_root spawn FindSkillDoc(claimed={}, target_cid=doc_cid, policy=policy);
  print("skill_doc_name", doc_cid, w.hit);
  return w.hit;
}
