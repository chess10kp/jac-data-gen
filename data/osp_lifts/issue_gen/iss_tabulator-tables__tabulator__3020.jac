"""tabulator-tables/tabulator#3020 — Deep match header filter for hierarchical tree rows."""

node Location {
    has id: str;
    has location: str;
    has color: str = "";
}

edge Child {}

walker TreeMatchWalker {
    has header_value: str;
    has column_name: str;
    has cache: dict[str, bool];
    has target_id: str = "";
    has collect_all: bool = False;
    has result: bool = False;
    has visible: list[str] = [];
    has claimed: dict[str, bool] = {};

    can walk with Location entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;

        if here.id in self.cache {
            if here.id == self.target_id {
                self.result = self.cache[here.id];
            }
            if self.collect_all and self.cache[here.id] {
                self.visible.append(here.id);
            }
            print({"id": here.id, "cached": self.cache[here.id]});
            disengage;
        }

        children: list[Location] = [here ->:Child:->][?:Location];
        for ch in children {
            visit ch;
        }

        any_child_match: bool = False;
        for ch in children {
            ch_id = ch.id;
            if ch_id in self.cache {
                if self.cache[ch_id] {
                    any_child_match = True;
                    break;
                }
            }
        }

        if any_child_match {
            self.cache[here.id] = True;
            if here.id == self.target_id {
                self.result = True;
            }
            if self.collect_all {
                self.visible.append(here.id);
            }
            print({"id": here.id, "match": True, "via": "descendant"});
            disengage;
        }

        field_val: str = "";
        if self.column_name == "location" {
            field_val = here.location;
        } elif self.column_name == "color" {
            field_val = here.color;
        }

        self_match: bool = False;
        if field_val != "" {
            fv = field_val.lower();
            hv = self.header_value.lower();
            if fv.find(hv) >= 0 {
                self_match = True;
            }
        }

        self.cache[here.id] = self_match;
        if here.id == self.target_id {
            self.result = self_match;
        }
        if self.collect_all and self_match {
            self.visible.append(here.id);
        }
        print({"id": here.id, "match": self_match, "via": "self"});
        disengage;
    }
}

obj DeepMatchFilter {
    has graph_root: Location | None = None;
    has id_index: dict[str, Location] = {};
    has cache: dict[str, bool] = {};

    def add_node(id: str, location: str, color: str = "", parent_id: str | None = None) -> None {
        node = Location(id=id, location=location, color=color);
        self.id_index[id] = node;
        if parent_id is None {
            if self.graph_root is None {
                self.graph_root = node;
                root ++> node;
            }
        } else {
            if parent_id in self.id_index {
                parent = self.id_index[parent_id];
                parent +>:Child:+> node;
            }
        }
    }

    def link(parent_id: str, child_id: str) {
        if parent_id in self.id_index and child_id in self.id_index {
            parent = self.id_index[parent_id];
            child = self.id_index[child_id];
            parent +>:Child:+> child;
        }
    }

    def clear_cache {
        self.cache = {};
    }

    def deep_match(header_value: str, node_id: str, column_name: str = "location") -> bool {
        if self.graph_root is None {
            return False;
        }
        if node_id not in self.id_index {
            return False;
        }
        w = self.graph_root spawn TreeMatchWalker(
            header_value=header_value,
            column_name=column_name,
            cache=self.cache,
            target_id=node_id,
            collect_all=False
        );
        if node_id in self.cache {
            return self.cache[node_id];
        }
        return w.result;
    }

    def visible_node_ids(header_value: str, column_name: str = "location") -> list[str] {
        self.clear_cache();
        if self.graph_root is None {
            return [];
        }
        w = self.graph_root spawn TreeMatchWalker(
            header_value=header_value,
            column_name=column_name,
            cache=self.cache,
            collect_all=True
        );
        out: list[str] = [];
        for vid in w.visible {
            out.append(vid);
        }
        return sorted(out);
    }
}
