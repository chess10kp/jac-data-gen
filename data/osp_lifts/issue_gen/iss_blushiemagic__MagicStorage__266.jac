"""blushiemagic/MagicStorage#266 — recursive crafting with environmental sources."""

node Recipe {
    has rid: str;
    has name: str;
}

node Material {
    has mid: str;
    has stock: int = 0;
}

node EnvSource {
    has eid: str;
    has kind: str;
}

edge Needs {}
edge SubRecipe {}

node CraftEngine {
    has recipes: dict[str, Recipe] = {};
    has materials: dict[str, Material] = {};
    has envs: dict[str, EnvSource] = {};
}

walker CollectNeeds {
    has max_depth: int = 0;
    has depth: int = 0;
    has claimed: dict[str, bool] = {};
    has needs: dict[str, int] = {};
    has envs: list[str] = [];
    has target_rid: str = "";
    has ok: bool = True;

    can walk_recipe with Recipe entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        print("recipe", here.rid);
        deps: list = [];
        for dep in [here ->:Needs:->][?:Material] {
            deps.append(dep);
        }
        for dep in [here ->:Needs:->][?:EnvSource] {
            deps.append(dep);
        }
        for dep in deps {
            visit dep;
        }
    }

    can walk_material with Material entry {
        if here.mid in self.claimed {
            skip;
        }
        self.claimed[here.mid] = True;
        print("material", here.mid);
        expanded = False;
        if self.depth < self.max_depth {
            subs: list = [here ->:SubRecipe:->][?:Recipe];
            for sr in subs {
                self.depth += 1;
                visit :0: [sr];
                self.depth -= 1;
                expanded = True;
            }
        }
        if not expanded {
            mid = here.mid;
            cur = 0;
            if mid in self.needs {
                cur = self.needs[mid] as int;
            }
            self.needs[mid] = cur + 1;
        }
    }

    can walk_env with EnvSource entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        print("env", here.eid);
        eid = here.eid;
        found = False;
        for e in self.envs {
            if e == eid {
                found = True;
            }
        }
        if not found {
            self.envs.append(eid);
        }
    }
}

def _sorted_strs(xs: list[str]) -> list[str] {
    copy: list[str] = [];
    for x in xs {
        copy.append(x);
    }
    return sorted(copy);
}

def _resolve(eng: CraftEngine, recipe_id: str, recursion_depth: int) -> dict | None {
    if recipe_id not in eng.recipes {
        return None;
    }
    r = eng.recipes[recipe_id] as Recipe;
    w = r spawn CollectNeeds(
        max_depth=recursion_depth,
        depth=0,
        claimed={},
        needs={},
        envs=[],
        target_rid=recipe_id,
        ok=True
    );
    if not w.ok {
        return None;
    }
    out: dict = {};
    out["needs"] = w.needs;
    out["envs"] = w.envs;
    return out;
}

def make_crafter -> CraftEngine {
    eng = CraftEngine();
    root ++> eng;
    water = EnvSource(eid="env_water", kind="water");
    root ++> water;
    eng.envs["env_water"] = water;
    bottle = Material(mid="bottle", stock=10);
    herb = Material(mid="herb", stock=10);
    iron = Material(mid="iron", stock=3);
    comp_a = Material(mid="comp_a", stock=0);
    comp_b = Material(mid="comp_b", stock=0);
    root ++> bottle;
    root ++> herb;
    root ++> iron;
    root ++> comp_a;
    root ++> comp_b;
    eng.materials["bottle"] = bottle;
    eng.materials["herb"] = herb;
    eng.materials["iron"] = iron;
    eng.materials["comp_a"] = comp_a;
    eng.materials["comp_b"] = comp_b;
    bottled_water = Recipe(rid="bottled_water", name="Bottled Water");
    potion = Recipe(rid="potion", name="Potion");
    flymeal = Recipe(rid="flymeal", name="Flymeal");
    diamond = Recipe(rid="diamond", name="Diamond");
    sub_a = Recipe(rid="sub_a", name="SubA");
    sub_b = Recipe(rid="sub_b", name="SubB");
    root ++> bottled_water;
    root ++> potion;
    root ++> flymeal;
    root ++> diamond;
    root ++> sub_a;
    root ++> sub_b;
    eng.recipes["bottled_water"] = bottled_water;
    eng.recipes["potion"] = potion;
    eng.recipes["flymeal"] = flymeal;
    eng.recipes["diamond"] = diamond;
    eng.recipes["sub_a"] = sub_a;
    eng.recipes["sub_b"] = sub_b;
    bottled_water +>:Needs:+> water;
    bottled_water +>:Needs:+> bottle;
    potion +>:Needs:+> herb;
    mat_bw = Material(mid="bottled_water", stock=0);
    root ++> mat_bw;
    eng.materials["bottled_water"] = mat_bw;
    potion +>:Needs:+> mat_bw;
    mat_bw +>:SubRecipe:+> bottled_water;
    flymeal +>:Needs:+> water;
    flymeal +>:Needs:+> iron;
    diamond +>:Needs:+> comp_a;
    diamond +>:Needs:+> comp_b;
    comp_a +>:SubRecipe:+> sub_a;
    comp_b +>:SubRecipe:+> sub_b;
    sub_a +>:Needs:+> iron;
    sub_b +>:Needs:+> iron;
    return eng;
}

def material_needs(eng: CraftEngine, recipe_id: str, recursion_depth: int) -> dict[str, int] | None {
    info = _resolve(eng, recipe_id, recursion_depth);
    if info is None {
        return None;
    }
    return info["needs"] as dict[str, int];
}

def can_craft(eng: CraftEngine, recipe_id: str, recursion_depth: int) -> bool {
    info = _resolve(eng, recipe_id, recursion_depth);
    if info is None {
        return False;
    }
    needs = info["needs"] as dict[str, int];
    for mid in needs {
        cnt = needs[mid] as int;
        if mid not in eng.materials {
            return False;
        }
        m = eng.materials[mid] as Material;
        if m.stock < cnt {
            return False;
        }
    }
    return True;
}

def craft(eng: CraftEngine, recipe_id: str, recursion_depth: int) -> dict | None {
    info = _resolve(eng, recipe_id, recursion_depth);
    if info is None {
        return None;
    }
    needs = info["needs"] as dict[str, int];
    envs = info["envs"] as list[str];
    for mid in needs {
        cnt = needs[mid] as int;
        if mid not in eng.materials {
            return None;
        }
        m = eng.materials[mid] as Material;
        if m.stock < cnt {
            return None;
        }
    }
    for mid in needs {
        cnt = needs[mid] as int;
        m = eng.materials[mid] as Material;
        m.stock -= cnt;
    }
    out: dict = {};
    out["recipe_id"] = recipe_id;
    out["needs"] = needs;
    out["envs"] = _sorted_strs(envs);
    return out;
}
