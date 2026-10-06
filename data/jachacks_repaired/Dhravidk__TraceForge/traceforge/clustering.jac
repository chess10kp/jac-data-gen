import from traceforge.features {
    cosine_like_overlap,
    dominant_failure_label,
    summarize_counts,
    top_k_indices
}

def failure_class_label(failure_class: str) -> str {
    labels = {
        "PREMATURE_COMPLETION": "Premature completion",
        "INVALID_PATCH": "Invalid patching",
        "WRONG_FILE_FOCUS": "Wrong-file focus",
        "OSCILLATION_LOOP": "Oscillation loop",
        "TOOL_MISUSE": "Tool misuse",
        "STALE_CONTEXT_OR_BAD_PLAN": "Stale context or bad plan",
        "REQUIREMENT_DRIFT": "Requirement drift",
        "UNKNOWN": "Recovered or unclassified",
    };
    return labels.get(failure_class, failure_class.replace("_", " ").title());
}

def _sequence_similarity(left: list[str], right: list[str]) -> float {
    if not left and not right {
        return 1.0;
    }
    return cosine_like_overlap(left, right);
}

def similarity_score(left: dict[str, any], right: dict[str, any]) -> float {
    left_scores = left.get("failure_class_scores", {});
    right_scores = right.get("failure_class_scores", {});
    left_failure_tokens: list[str] = [];
    right_failure_tokens: list[str] = [];
    for key in left_scores {
        left_failure_tokens.append(f"{key}:{round(float(left_scores[key]), 2)}");
    }
    for key in right_scores {
        right_failure_tokens.append(f"{key}:{round(float(right_scores[key]), 2)}");
    }

    failure_overlap = cosine_like_overlap(left_failure_tokens, right_failure_tokens);
    sequence_similarity = _sequence_similarity(left.get("step_kind_sequence", []), right.get("step_kind_sequence", []));
    lexical_overlap = cosine_like_overlap(
        left.get("top_files", []) + left.get("top_test_names", []) + left.get("top_error_keywords", []),
        right.get("top_files", []) + right.get("top_test_names", []) + right.get("top_error_keywords", []),
    );
    numeric_distance = (
        abs(float(left.get("num_steps", 0)) - float(right.get("num_steps", 0)))
        + abs(float(left.get("num_tests", 0)) - float(right.get("num_tests", 0)))
        + abs(float(left.get("num_patches", 0)) - float(right.get("num_patches", 0)))
        + abs(float(left.get("repeated_step_ratio", 0.0)) - float(right.get("repeated_step_ratio", 0.0)))
        + abs(float(left.get("repeated_file_ratio", 0.0)) - float(right.get("repeated_file_ratio", 0.0)))
        + abs(float(left.get("loop_score", 0.0)) - float(right.get("loop_score", 0.0)))
    );
    numeric_similarity = 1.0 - min(1.0, numeric_distance / 6.0);
    return round(
        (0.35 * failure_overlap)
        + (0.20 * sequence_similarity)
        + (0.20 * lexical_overlap)
        + (0.15 * numeric_similarity)
        + (0.10 * lexical_overlap),
        4,
    );
}

def top_k_neighbors(target_index: int, fingerprints: list[dict[str, any]], k: int = 5) -> list[dict[str, any]] {
    scores: list[dict[str, any]] = [];
    target = fingerprints[target_index];
    for (index, other) in enumerate(fingerprints) {
        if index == target_index {
            continue;
        }
        scores.append({"index": index, "score": similarity_score(target, other)});
    }
    top = top_k_indices([float(item["score"]) for item in scores], k);
    return [scores[index] for index in top];
}

def threshold_edges(neighbor_sets: list[list[dict[str, any]]], threshold: float) -> list[tuple[int, int, float]] {
    edges: list[tuple[int, int, float]] = [];
    for (source_index, neighbors) in enumerate(neighbor_sets) {
        for neighbor in neighbors {
            if float(neighbor["score"]) >= threshold {
                edges.append((source_index, int(neighbor["index"]), float(neighbor["score"])));
            }
        }
    }
    return edges;
}

def _connected_components(size: int, edges: list[tuple[int, int, float]]) -> list[list[int]] {
    adjacency: dict[int, list[int]] = {};
    for index = 0 while index<size with index+=1 {
        adjacency[index] = [];
    }
    for edge in edges {
        left = edge[0];
        right = edge[1];
        adjacency[left].append(right);
        adjacency[right].append(left);
    }

    seen: set[int] = set();
    components: list[list[int]] = [];
    for node_index = 0 while node_index<size with node_index+=1 {
        if node_index in seen {
            continue;
        }
        stack = [node_index];
        component: list[int] = [];
        seen.add(node_index);
        while stack {
            current = stack.pop();
            component.append(current);
            for neighbor in adjacency[current] {
                if neighbor in seen {
                    continue;
                }
                seen.add(neighbor);
                stack.append(neighbor);
            }
        }
        components.append(sorted(component));
    }
    return components;
}

def _medoid_run_id(component_records: list[dict[str, any]]) -> str {
    if len(component_records) == 1 {
        return str(component_records[0]["run_id"]);
    }
    best_run_id = str(component_records[0]["run_id"]);
    best_score = -1.0;
    for record in component_records {
        total = 0.0;
        count = 0;
        for other in component_records {
            if record["run_id"] == other["run_id"] {
                continue;
            }
            total += similarity_score(record["fingerprint"], other["fingerprint"]);
            count += 1;
        }
        average = total / max(count, 1);
        if average > best_score {
            best_score = average;
            best_run_id = str(record["run_id"]);
        }
    }
    return best_run_id;
}

def _component_similar_pairs(
    component: list[int],
    edges: list[tuple[int, int, float]],
    family_records: list[dict[str, any]],
) -> list[dict[str, any]] {
    component_set: set[int] = set(component);
    dedup: dict[str, dict[str, any]] = {};
    for edge in edges {
        left_index = edge[0];
        right_index = edge[1];
        if left_index not in component_set or right_index not in component_set {
            continue;
        }
        left_run_id = str(family_records[left_index]["run_id"]);
        right_run_id = str(family_records[right_index]["run_id"]);
        if left_run_id == right_run_id {
            continue;
        }
        left_id = left_run_id;
        right_id = right_run_id;
        if right_id < left_id {
            left_id = right_run_id;
            right_id = left_run_id;
        }
        pair_key = left_id + "||" + right_id;
        score = float(edge[2]);
        existing = dedup.get(pair_key);
        if existing is None or score > float(existing["score"]) {
            dedup[pair_key] = {
                "left_run_id": left_id,
                "right_run_id": right_id,
                "score": score,
            };
        }
    }
    return sorted(
        [dedup[key] for key in dedup],
        key=lambda (item: any) -> any { (-float(item["score"]), item["left_run_id"], item["right_run_id"]) },
    );
}

def build_clusters(run_records: list[dict[str, any]], batch_id: str, top_k: int = 3, threshold: float = 0.55) -> list[dict[str, any]] {
    by_family: dict[str, list[dict[str, any]]] = {};
    for record in run_records {
        family = str(record.get("primary_failure") or dominant_failure_label(record["fingerprint"]));
        if family not in by_family {
            by_family[family] = [];
        }
        by_family[family].append(record);
    }

    clusters: list[dict[str, any]] = [];
    for family in by_family {
        family_records = by_family[family];
        fingerprints = [record["fingerprint"] for record in family_records];
        neighbor_sets: list[list[dict[str, any]]] = [];
        for index = 0 while index<len(fingerprints) with index+=1 {
            neighbor_sets.append(top_k_neighbors(index, fingerprints, top_k));
        }
        edges = threshold_edges(neighbor_sets, threshold);
        components = _connected_components(len(family_records), edges);
        for (component_index, component) in enumerate(components) {
            component_records = [family_records[index] for index in component];
            similar_pairs = _component_similar_pairs(component, edges, family_records);
            component_files: list[str] = [];
            component_errors: list[str] = [];
            component_tests: list[str] = [];
            run_ids: list[str] = [];
            for record in component_records {
                run_ids.append(str(record["run_id"]));
                component_files.extend(record["fingerprint"].get("top_files", []));
                component_errors.extend(record["fingerprint"].get("top_error_keywords", []));
                component_tests.extend(record["fingerprint"].get("top_test_names", []));
            }
            cluster_id = f"{batch_id}:{family.lower()}:{component_index}";
            clusters.append(
                {
                    "cluster_id": cluster_id,
                    "label": failure_class_label(family),
                    "failure_class": family,
                    "size": len(component_records),
                    "medoid_run_id": _medoid_run_id(component_records),
                    "run_ids": run_ids,
                    "similar_pairs": similar_pairs,
                    "recurring_files": summarize_counts(component_files, 5),
                    "recurring_errors": summarize_counts(component_errors, 5),
                    "recurring_tests": summarize_counts(component_tests, 5),
                    "summary": f"{failure_class_label(family)} cluster with {len(component_records)} run(s).",
                }
            );
        }
    }

    return sorted(clusters, key=lambda (cluster: any) -> any { (-cluster["size"], cluster["cluster_id"]) });
}

def find_cluster(clusters: list[dict[str, any]], cluster_id: str) -> dict[str, any] {
    for cluster in clusters {
        if cluster["cluster_id"] == cluster_id {
            return cluster;
        }
    }
    return {};
}
