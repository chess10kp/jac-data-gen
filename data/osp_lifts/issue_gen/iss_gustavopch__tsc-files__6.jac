# tsc-files lift: type-check changed files plus everything that recursively
# depends on them. gustavopch/tsc-files#6
#
# Python baseline API (module tsc_files):
#   class DepGraph:
#     add_file(fid)            -> None   (unknown-id tolerant)
#     add_dep(user, provider)  -> None
#     dependents(fid)          -> sorted list of direct dependents
#     closure(fid)             -> sorted list of files affected by fid change
#   unknown ids in dependents/closure -> returns [] (tolerant)

node File {
  has fid: str;
}

edge DependsOn {}

obj DepGraph {
  has by_id: dict[str, File] = {};

  def add_file(fid: str) -> None {
    if fid not in self.by_id {
      f = File(fid=fid);
      root ++> f;
      self.by_id[fid] = f;
    }
  }

  def add_dep(user: str, provider: str) -> None {
    self.add_file(user);
    self.add_file(provider);
    u = self.by_id[user];
    p = self.by_id[provider];
    u +>:DependsOn:+> p;
  }

  def dependents(fid: str) -> list[str] {
    if fid not in self.by_id { return []; }
    out: list[str] = [];
    for ch in [self.by_id[fid] <-:DependsOn:-][?:File] {
      out.append(ch.fid);
    }
    return sorted(out);
  }

  def closure(fid: str) -> list[str] {
    if fid not in self.by_id { return []; }
    w = self.by_id[fid] spawn DepsClosure(claimed={});
    return sorted(w.affected);
  }
}

# Walks the reversed DependsOn edges: every file that (transitively) imports
# the touched file must be re-type-checked. Claim-map + skip handles diamond
# revisits without truncating the closure.
walker DepsClosure {
  has claimed: dict[str, bool] = {};
  has affected: list[str] = [];

  can step with File entry {
    if here.fid in self.claimed { skip; }
    self.claimed[here.fid] = True;
    if here.fid not in self.affected {
      self.affected.append(here.fid);
    }
    # dependents = nodes with an incoming DependsOn edge from here
    kids: list[File] = [here <-:DependsOn:-][?:File];
    if len(kids) == 0 { disengage; }
    visit kids;
  }
}
