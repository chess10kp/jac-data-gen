"""Walkers that manage menu cycles, menu items, and scraping results."""


import from ..domain.edges { Features, Hosts }
import from ..domain.nodes { DiningHall, MenuCycle, MenuItem, ScrapeJob }
walker :pub IngestScrapedMenu {
    has hall_id: str;
    has scraped_at: str;
    has items: list[dict];
    has inserted: int = 0;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can attach_items with DiningHall entry {
        for raw in self.items {
            mi = MenuItem(
                item_id=raw["item_id"],
                name=raw["name"],
                category=raw.get("category", "other"),
                station_label=raw.get("station_label", ""),
                unit_cost_usd=raw.get("unit_cost_usd", 0.0),
                per_serving_oz=raw.get("per_serving_oz", 0.0),
                is_vegetarian=raw.get("is_vegetarian", False),
                is_vegan=raw.get("is_vegan", False),
                contains_dairy=raw.get("contains_dairy", False),
                contains_gluten=raw.get("contains_gluten", False),
                is_constant=raw.get("is_constant", False)
            );
            here +>: Features(first_seen_on=self.scraped_at) :+> mi;
            self.inserted += 1;
        }
    }

    can finish with Root exit {
        report {
            "hall_id": self.hall_id,
            "inserted": self.inserted,
            "scraped_at": self.scraped_at
        };
    }
}

walker :pub ListMenuForHall {
    has hall_id: str;
    has category_filter: str = "";
    has exclude_constant: bool = False;
    has items: list[dict] = [];

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk with DiningHall entry {
        visit [->:Features:->][?:MenuItem];
    }

    can collect with MenuItem entry {
        if self.exclude_constant and here.is_constant {
            skip;
        }
        if self.category_filter != "" and here.category != self.category_filter {
            skip;
        }
        self.items.append({
            "item_id": here.item_id,
            "name": here.name,
            "category": here.category,
            "station": here.station_label,
            "cost_usd": here.unit_cost_usd,
            "portion_oz": here.per_serving_oz,
            "vegetarian": here.is_vegetarian,
            "vegan": here.is_vegan
        });
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "items": self.items};
    }
}

walker :pub ClassifyMenuItem {
    has item_id: str;
    has updated: bool = False;
    has category: str = "other";

    can start with Root entry {
        visit [-->][?:MenuItem, item_id == self.item_id];
    }

    can classify with MenuItem entry {
        name_lower = here.name.lower();
        if "chicken" in name_lower or "beef" in name_lower or "pork" in name_lower or "tofu" in name_lower or "fish" in name_lower or "salmon" in name_lower {
            here.category = "protein";
        } elif "rice" in name_lower or "pasta" in name_lower or "bread" in name_lower or "quinoa" in name_lower or "bagel" in name_lower {
            here.category = "grain";
        } elif "yogurt" in name_lower or "cheese" in name_lower or "milk" in name_lower {
            here.category = "dairy";
        } elif "apple" in name_lower or "banana" in name_lower or "berry" in name_lower or "orange" in name_lower or "grape" in name_lower {
            here.category = "fruit";
        } elif "salad" in name_lower or "broccoli" in name_lower or "carrot" in name_lower or "spinach" in name_lower or "kale" in name_lower {
            here.category = "vegetable";
        } elif "juice" in name_lower or "coffee" in name_lower or "tea" in name_lower or "soda" in name_lower {
            here.category = "beverage";
        } else {
            here.category = "other";
        }
        self.category = here.category;
        self.updated = True;
    }

    can finish with Root exit {
        report {"item_id": self.item_id, "category": self.category, "updated": self.updated};
    }
}

walker :pub StartMenuCycle {
    has cycle_id: str;
    has label: str;
    has week_of: str;
    has hall_id: str;
    has created: bool = False;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can attach with DiningHall entry {
        cycle = MenuCycle(
            cycle_id=self.cycle_id,
            label=self.label,
            week_of=self.week_of,
            hall_id=self.hall_id
        );
        here +>: Hosts(since=self.week_of) :+> cycle;
        self.created = True;
    }

    can finish with Root exit {
        report {"created": self.created, "cycle_id": self.cycle_id};
    }
}

walker :pub MarkConstantItems {
    has hall_id: str;
    has names: list[str];
    has marked: int = 0;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk with DiningHall entry {
        visit [->:Features:->][?:MenuItem];
    }

    can mark with MenuItem entry {
        for n in self.names {
            if n.lower() == here.name.lower() {
                here.is_constant = True;
                self.marked += 1;
            }
        }
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "marked": self.marked};
    }
}

walker :pub RecordScrapeJob {
    has job_id: str;
    has source_url: str;
    has started_at: str;
    has finished_at: str;
    has items_found: int;
    has success: bool;
    has error_message: str = "";

    can start with Root entry {
        job = ScrapeJob(
            job_id=self.job_id,
            source_url=self.source_url,
            started_at=self.started_at,
            finished_at=self.finished_at,
            items_found=self.items_found,
            success=self.success,
            error_message=self.error_message
        );
        root ++> job;
        report {"job_id": self.job_id, "success": self.success};
    }
}

walker :pub LookupMenuItemByName {
    has name_query: str;
    has hall_id: str = "";
    has matches: list[dict] = [];

    can start with Root entry {
        if self.hall_id != "" {
            visit [-->][?:DiningHall, hall_id == self.hall_id];
        } else {
            visit [-->][?:MenuItem];
        }
    }

    can hall_walk with DiningHall entry {
        visit [->:Features:->][?:MenuItem];
    }

    can `match with MenuItem entry {
        if self.name_query.lower() in here.name.lower() {
            self.matches.append({
                "item_id": here.item_id,
                "name": here.name,
                "category": here.category
            });
        }
    }

    can finish with Root exit {
        report {"query": self.name_query, "matches": self.matches};
    }
}

walker :pub NormalizeMenuNames {
    has hall_id: str;
    has normalized_count: int = 0;

    can start with Root entry {
        visit [-->][?:DiningHall, hall_id == self.hall_id];
    }

    can walk with DiningHall entry {
        visit [->:Features:->][?:MenuItem];
    }

    can clean with MenuItem entry {
        cleaned = here.name.strip();
        cleaned = cleaned.replace("  ", " ");
        if cleaned != here.name {
            here.name = cleaned;
            self.normalized_count += 1;
        }
    }

    can finish with Root exit {
        report {"hall_id": self.hall_id, "normalized": self.normalized_count};
    }
}
