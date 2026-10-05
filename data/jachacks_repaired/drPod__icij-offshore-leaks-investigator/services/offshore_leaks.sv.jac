import db.icij_db;
import from byllm.llm { Model }

glob llm_model: Model = Model(model_name="anthropic/claude-haiku-4-5-20251001");

node Entity {
    has node_id: str;
    has name: str;
    has node_type: str = "entity";
    has countries: str = "";
    has country_codes: str = "";
    has source_id: str = "";
    has jurisdiction: str = "";
    has is_power_player: bool = False;
    has power_player_title: str = "";
    has power_player_release: str = "";
    has hop: int = 0;
}

edge LinkedTo {
    has rel_type: str;
    has link: str = "";
    has source_id: str = "";
}

"""Summarize the structural connection between two persons in an offshore
entity graph. Output 2-3 sentences describing ONLY the graph structure:
who connects to whom, through which entities and intermediaries, in which
jurisdictions, via what relationship types. Do NOT speculate about motives,
legality, or tax implications. Stick strictly to what the edges show."""
def summarize_connection(
    path_description: str,
    person_a: str,
    person_b: str,
    jurisdictions: str,
    entity_count: int,
    intermediary_count: int,
    hop_count: int
) -> str by llm_model();

def:pub search(query: str, limit: int = 30) -> dict {
    results = db.icij_db.search_nodes(query=query, limit=limit);
    return {
        "success": True,
        "results": results,
        "count": len(results)
    };
}

def:pub investigate(node_id: str, max_depth: int = 3, max_nodes: int = 500) -> dict {
    subgraph = db.icij_db.get_subgraph(
        center_node_id=node_id,
        max_depth=max_depth,
        max_nodes=max_nodes
    );
    if not subgraph["nodes"] {
        return {"success": False, "error": "Node not found"};
    }
    return {
        "success": True,
        "nodes": subgraph["nodes"],
        "edges": subgraph["edges"],
        "power_players_found": subgraph["power_players_found"],
        "truncated": subgraph["truncated"],
        "stats": subgraph["stats"]
    };
}

def:pub get_node_detail(node_id: str) -> dict {
    detail = db.icij_db.get_node_detail(node_id);
    if not detail {
        return {"success": False, "error": "Node not found"};
    }
    return {
        "success": True,
        "node": detail
    };
}

def:pub get_db_stats() -> dict {
    stats = db.icij_db.get_stats();
    return {
        "success": True,
        "stats": stats
    };
}

def:pub get_power_players() -> dict {
    data = db.icij_db.get_power_players();
    return {
        "success": True,
        "players": data["players"],
        "connected_pairs": data["connected_pairs"],
        "connectable_count": data["connectable_count"]
    };
}

def:pub find_connections(node_ids: list) -> dict {
    if len(node_ids) < 2 {
        return {"success": False, "error": "Select at least 2 Power Players"};
    }

    # Spawn the PathFinder agent — it discovers paths, materializes the graph,
    # traverses it, and generates AI summaries
    w = PathFinder(target_ids=node_ids);
    root spawn w;

    return w.result;
}

walker :pub PathFinder {
    has target_ids: list[str] = [];
    has max_depth: int = 6;
    has result: dict = {};
    has collected_nodes: list[dict] = [];
    has visited_ids: list[str] = [];
    has bfs_result: dict = {};

    can start with Root entry {
        if len(self.target_ids) < 2 {
            self.result = {"success": False, "error": "Need at least 2 targets"};
            report self.result;
            disengage;
        }

        # Step 1: Use Python BFS tool to discover paths between targets
        self.bfs_result = db.icij_db.find_connections(
            node_ids=self.target_ids,
            max_depth=8
        );

        if not self.bfs_result["nodes"] {
            self.result = {
                "success": True,
                "nodes": [],
                "edges": [],
                "paths_found": [],
                "paths_not_found": self.bfs_result["paths_not_found"],
                "summaries": [],
                "stats": self.bfs_result["stats"]
            };
            report self.result;
            disengage;
        }

        # Step 2: Materialize discovered paths as a Jac graph
        node_map: dict = {};
        for n in self.bfs_result["nodes"] {
            entity = Entity(
                node_id=n["node_id"],
                name=n["name"],
                node_type=n["node_type"],
                countries=n.get("countries", ""),
                country_codes=n.get("country_codes", ""),
                source_id=n.get("source_id", ""),
                jurisdiction=n.get("jurisdiction", ""),
                is_power_player=n.get("is_power_player", False),
                power_player_title=n.get("power_player_title", ""),
                power_player_release=n.get("power_player_release", ""),
                hop=n.get("hop", 0)
            );
            here ++> entity;
            node_map[n["node_id"]] = entity;
        }

        for e in self.bfs_result["edges"] {
            src = node_map.get(e["source"]);
            tgt = node_map.get(e["target"]);
            if src and tgt {
                src +>:LinkedTo(
                    rel_type=e["rel_type"],
                    link=e.get("link", ""),
                    source_id=e.get("source_id", "")
                ):+> tgt;
            }
        }

        # Step 3: Traverse the materialized graph
        for entity in [-->][?:Entity] {
            visit entity;
        }
    }

    can examine with Entity entry {
        # Agent traverses each node in the discovered path
        if here.node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(here.node_id);

        self.collected_nodes.append({
            "node_id": here.node_id,
            "name": here.name,
            "node_type": here.node_type,
            "countries": here.countries,
            "country_codes": here.country_codes,
            "source_id": here.source_id,
            "jurisdiction": here.jurisdiction,
            "is_power_player": here.is_power_player,
            "power_player_title": here.power_player_title,
            "power_player_release": here.power_player_release,
            "hop": here.hop
        });
    }

    can finish with Root exit {
        # Step 4: Generate AI summaries for each discovered path
        summaries: list = [];
        for path_info in self.bfs_result["paths_found"] {
            path_nodes = [n for n in self.collected_nodes
                          if n["node_id"] in path_info["path_node_ids"]];
            path_edges = [e for e in self.bfs_result["edges"]
                          if e["source"] in path_info["path_node_ids"]
                          and e["target"] in path_info["path_node_ids"]];

            desc = db.icij_db.build_path_description(path_nodes, path_edges);

            jurisdictions_set: set = set();
            entity_count = 0;
            intermediary_count = 0;
            for n in path_nodes {
                j = n.get("jurisdiction", "") or n.get("countries", "");
                if j { jurisdictions_set.add(j); }
                if n["node_type"] == "entity" { entity_count += 1; }
                if n["node_type"] == "intermediary" { intermediary_count += 1; }
            }

            start_node = db.icij_db.get_node(path_info["start_id"]);
            end_node = db.icij_db.get_node(path_info["end_id"]);

            cached = db.icij_db.get_cached_summary(path_info["start_id"], path_info["end_id"]);
            if cached {
                summary_text = cached;
            } else {
                try {
                    summary_text = summarize_connection(
                        path_description=desc,
                        person_a=start_node["name"] if start_node else "",
                        person_b=end_node["name"] if end_node else "",
                        jurisdictions=", ".join(jurisdictions_set),
                        entity_count=entity_count,
                        intermediary_count=intermediary_count,
                        hop_count=path_info["hops"]
                    );
                    db.icij_db.save_cached_summary(path_info["start_id"], path_info["end_id"], summary_text);
                } except Exception as e {
                    summary_text = f"{start_node['name'] if start_node else ''} and {end_node['name'] if end_node else ''} are connected through {path_info['hops']} hops via {entity_count} entities.";
                    db.icij_db.save_cached_summary(path_info["start_id"], path_info["end_id"], summary_text);
                }
            }

            summaries.append({
                "start_name": start_node["name"] if start_node else "",
                "end_name": end_node["name"] if end_node else "",
                "summary": summary_text,
                "hops": path_info["hops"]
            });
        }

        # Clean up materialized graph
        for entity in [-->][?:Entity] {
            del entity;
        }

        # Step 5: Generate investigation decision log
        investigation_log = db.icij_db.generate_investigation_log(self.bfs_result);

        # Step 6: Report findings
        self.result = {
            "success": True,
            "nodes": self.collected_nodes,
            "edges": self.bfs_result["edges"],
            "paths_found": self.bfs_result["paths_found"],
            "paths_not_found": self.bfs_result["paths_not_found"],
            "summaries": summaries,
            "investigation_log": investigation_log,
            "stats": self.bfs_result["stats"]
        };
        report self.result;
    }
}

walker :pub Investigate {
    has center_id: str = "";
    has max_depth: int = 3;
    has max_nodes: int = 500;
    has collected_nodes: list[dict] = [];
    has collected_edges: list[dict] = [];
    has power_players: list[dict] = [];
    has visited_ids: list[str] = [];

    can start with Root entry {
        subgraph = db.icij_db.get_subgraph(
            center_node_id=self.center_id,
            max_depth=self.max_depth,
            max_nodes=self.max_nodes
        );

        node_map: dict = {};
        for n in subgraph["nodes"] {
            entity = Entity(
                node_id=n["node_id"],
                name=n["name"],
                node_type=n["node_type"],
                countries=n.get("countries", ""),
                country_codes=n.get("country_codes", ""),
                source_id=n.get("source_id", ""),
                jurisdiction=n.get("jurisdiction", ""),
                is_power_player=n.get("is_power_player", False),
                power_player_title=n.get("power_player_title", ""),
                power_player_release=n.get("power_player_release", ""),
                hop=n.get("hop", 0)
            );
            here ++> entity;
            node_map[n["node_id"]] = entity;
        }

        for e in subgraph["edges"] {
            src = node_map.get(e["source"]);
            tgt = node_map.get(e["target"]);
            if src and tgt {
                src +>:LinkedTo(
                    rel_type=e["rel_type"],
                    link=e.get("link", ""),
                    source_id=e.get("source_id", "")
                ):+> tgt;
            }
        }

        for entity in [-->][?:Entity] {
            if entity.node_id == self.center_id {
                visit entity;
            }
        }
    }

    can examine with Entity entry {
        if here.node_id in self.visited_ids {
            return;
        }
        self.visited_ids.append(here.node_id);

        self.collected_nodes.append({
            "node_id": here.node_id,
            "name": here.name,
            "node_type": here.node_type,
            "countries": here.countries,
            "source_id": here.source_id,
            "is_power_player": here.is_power_player,
            "power_player_title": here.power_player_title,
            "power_player_release": here.power_player_release,
            "hop": here.hop
        });

        if here.is_power_player {
            self.power_players.append({
                "node_id": here.node_id,
                "name": here.name,
                "title": here.power_player_title,
                "release": here.power_player_release,
                "hop": here.hop
            });
        }

        visit [<-->][?:Entity];
    }

    can finish with Root exit {
        for entity in [-->][?:Entity] {
            del entity;
        }

        report {
            "success": True,
            "nodes": self.collected_nodes,
            "edges": self.collected_edges,
            "power_players_found": self.power_players,
            "stats": {
                "total_nodes": len(self.collected_nodes),
                "total_edges": len(self.collected_edges)
            }
        };
    }
}
