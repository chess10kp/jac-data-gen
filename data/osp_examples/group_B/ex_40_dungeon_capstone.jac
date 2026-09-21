"""Dungeon crawl capstone.

Chambers describe their effect on adventurers through polymorphic
``loot_gain`` / ``damage_taken`` / ``blocks_path`` methods that each
subtype overrides, so one hero ability handles every room kind and can
``disengage`` when a trap is lethal or a boss too strong. A rogue
subclass overrides the exploration ability to sneak to treasure only.
Exit abilities run innermost-first (post-order), so each chamber's
gold total already includes its whole subtree when its parent's exit
sums it up.
"""

node DungeonArea {
    has title: str;
    has gold_here: int = 0;
    has gold_total: int = 0;

    def loot_gain() -> int {
        return 0;
    }

    def damage_taken() -> int {
        return 0;
    }

    def blocks_path() -> bool {
        return False;
    }
}

node TreasureRoom(DungeonArea) {
    override def loot_gain() -> int {
        return self.gold_here;
    }
}

node TrapRoom(DungeonArea) {
    has damage: int = 0;

    override def damage_taken() -> int {
        return self.damage;
    }
}

node BossLair(DungeonArea) {
    has boss_hp: int = 0;

    override def loot_gain() -> int {
        return 0 if self.boss_hp > 60 else 500;
    }

    override def blocks_path() -> bool {
        return self.boss_hp > 60;
    }
}

walker Hero {
    has hero_name: str;
    has hp: int = 100;
    has loot: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can explore with DungeonArea entry {
        if here.blocks_path() {
            print(f"[{self.hero_name}] retreats from {here.title}");
            disengage;
        }
        hurt = here.damage_taken();
        if hurt > 0 {
            self.hp -= hurt;
            print(f"[{self.hero_name}] takes {hurt} damage in {here.title} "
                  f"(hp={self.hp})");
            if self.hp <= 0 {
                print(f"[{self.hero_name}] collapses in {here.title}");
                disengage;
            }
        }
        gain = here.loot_gain();
        if gain > 0 {
            self.loot += gain;
            print(f"[{self.hero_name}] gains {gain} gold in {here.title}");
        }
        visit : 0 : [-->];  # depth-first: descend before moving sideways
    }

    # Post-order aggregation: children have already exited, so their
    # gold_total fields are final when this parent's exit runs.
    can roll_up with DungeonArea exit {
        child_gold = 0;
        for child in [-->][?:DungeonArea] {
            child_gold += child.gold_total;
        }
        here.gold_total = here.gold_here + child_gold;
        print(f"[exit] {here.title}: subtree gold = {here.gold_total}");
    }
}

walker Rogue(Hero) {

    override can explore with DungeonArea entry {
        if here.blocks_path() {
            print(f"[{self.hero_name}] sneaks past {here.title} unseen");
        } else {
            gain = here.loot_gain() * 2;  # twice the loot, no fighting
            if gain > 0 {
                self.loot += gain;
                print(f"[{self.hero_name}] picks locks in {here.title} "
                      f"(+{gain} gold)");
            }
        }
        visit : 0 : [-->];
    }
}

with entry {
    entrance = DungeonArea(title="Entrance");
    crossroads = DungeonArea(title="Crossroads");
    vault = TreasureRoom(title="Old Vault", gold_here=250);
    spikes = TrapRoom(title="Spike Corridor", damage=30);
    hoard = TreasureRoom(title="Dragon Hoard", gold_here=400);
    lair = BossLair(title="Throne of Ash", boss_hp=45);
    root ++> entrance ++> crossroads;
    crossroads ++> vault ++> hoard;
    crossroads ++> spikes ++> lair;

    knight = Hero(hero_name="knight");
    root spawn knight;
    print(f"knight finished with {knight.loot} gold, hp={knight.hp}");

    sneaky = Rogue(hero_name="rogue");
    root spawn sneaky;
    print(f"rogue finished with {sneaky.loot} gold");
}
