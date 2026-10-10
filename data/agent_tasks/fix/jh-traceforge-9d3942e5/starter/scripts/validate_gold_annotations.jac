import argparse;
import json;
import from collections { Counter }
import from pathlib { Path }
import from sys { argv }

glob ALLOWED_FAILURE_CLASSES: set[str] = {
    "PREMATURE_COMPLETION",
    "INVALID_PATCH",
    "WRONG_FILE_FOCUS",
    "OSCILLATION_LOOP",
    "TOOL_MISUSE",
    "STALE_CONTEXT_OR_BAD_PLAN",
    "REQUIREMENT_DRIFT",
    "UNKNOWN",
};

def _render_markdown(payload: dict[str, any]) -> str {
    annotations = payload.get("annotations", []);
    substantive = sum([1 for item in annotations if item.get("group") == "substantive"]);
    startup = sum([1 for item in annotations if item.get("group") == "startup"]);
    lines = [
        "# TraceForge Gold Annotation Worksheet",
        "",
        "- Batch ID: `" + str(payload.get("batch_id", "")) + "`",
        "- Substantive runs: " + str(substantive),
        "- Startup runs: " + str(startup),
        "",
        "Annotate each run from the raw trajectory only.",
        "",
    ];
    for item in annotations {
        lines.append("## Run `" + str(item.get("run_id", "")) + "`");
        lines.append("");
        lines.append("- Group: " + str(item.get("group", "")));
        lines.append("- Task title: " + str(item.get("task_title", "")));
        lines.append("- Source path: `" + str(item.get("source_path", "")) + "`");
        lines.append("- Step count: " + str(item.get("step_count", 0)));
        lines.append("- Gold failure class: " + str(item.get("gold_failure_class", "")));
        lines.append("- Gold critical step idx: " + str(item.get("gold_critical_step_idx", -1)));
        lines.append("- Gold supporting steps: " + str(item.get("gold_supporting_steps", [])));
        lines.append("- Gold short rationale: " + str(item.get("gold_short_rationale", "")));
        lines.append("- Gold memory rule useful (yes/no): " + str(item.get("gold_memory_rule_useful", "")));
        lines.append("");
    }
    return "\n".join(lines).strip() + "\n";
}

def validate_payload(payload: dict[str, any]) -> list[str] {
    errors: list[str] = [];
    annotations = payload.get("annotations");
    if not isinstance(annotations, list) {
        return ["Payload must contain an 'annotations' list."];
    }

    for item in annotations {
        run_id = str(item.get("run_id") or "<missing-run-id>");
        failure_class = str(item.get("gold_failure_class") or "");
        memory_rule = str(item.get("gold_memory_rule_useful") or "").lower();
        rationale = str(item.get("gold_short_rationale") or "").strip();
        step_count = int(item.get("step_count") or 0);
        critical_step_idx = int(item.get("gold_critical_step_idx", -1));
        supporting_steps = item.get("gold_supporting_steps") or [];

        if failure_class not in ALLOWED_FAILURE_CLASSES {
            errors.append(run_id + ": invalid gold_failure_class `" + failure_class + "`.");
        }
        if memory_rule not in {"yes", "no"} {
            errors.append(run_id + ": gold_memory_rule_useful must be `yes` or `no`.");
        }
        if not rationale {
            errors.append(run_id + ": gold_short_rationale is empty.");
        }
        if not isinstance(supporting_steps, list) {
            errors.append(run_id + ": gold_supporting_steps must be a list.");
            supporting_steps = [];
        }
        for step_idx in supporting_steps {
            if int(step_idx) < 0 or int(step_idx) >= step_count {
                errors.append(
                    run_id
                    + ": supporting step "
                    + str(step_idx)
                    + " is outside 0.."
                    + str(max(step_count - 1, 0))
                    + "."
                );
            }
        }
        if critical_step_idx == -1 {
            if step_count > 0 and failure_class != "UNKNOWN" {
                errors.append(run_id + ": non-UNKNOWN failure class requires a concrete gold_critical_step_idx.");
            }
            if supporting_steps {
                errors.append(run_id + ": supporting steps must be empty when gold_critical_step_idx is -1.");
            }
        } else {
            if critical_step_idx < 0 or critical_step_idx >= step_count {
                errors.append(
                    run_id
                    + ": gold_critical_step_idx "
                    + str(critical_step_idx)
                    + " is outside 0.."
                    + str(max(step_count - 1, 0))
                    + "."
                );
            }
            if not supporting_steps {
                errors.append(run_id + ": gold_supporting_steps must contain at least one step when a critical step is set.");
            }
        }
    }
    return errors;
}

def build_parser() -> any {
    parser = argparse.ArgumentParser(description="Validate and optionally refresh a TraceForge gold annotation worksheet.");
    parser.add_argument("annotation_path", help="Path to the gold annotation JSON file.");
    parser.add_argument("--rewrite-markdown", action="store_true", help="Rewrite the sibling markdown worksheet from the JSON payload.");
    return parser;
}

def main(arg_list: list[str] = []) -> int {
    parser = build_parser();
    args = parser.parse_args(arg_list);

    annotation_path = Path(args.annotation_path);
    payload = json.loads(annotation_path.read_text(encoding="utf-8"));
    errors = validate_payload(payload);
    if errors {
        print("Validation failed:");
        for error in errors {
            print("- " + str(error));
        }
        return 1;
    }

    annotations = payload.get("annotations", []);
    counts = Counter([str(item.get("gold_failure_class") or "") for item in annotations]);
    print("Validated " + str(len(annotations)) + " annotations from " + str(annotation_path) + ".");
    for pair in sorted(counts.items(), key=lambda item: any -> any : item[0]) {
        print("- " + str(pair[0]) + ": " + str(pair[1]));
    }

    if args.rewrite_markdown {
        markdown_path = annotation_path.with_suffix(".md");
        markdown_path.write_text(_render_markdown(payload), encoding="utf-8");
        print("Rewrote " + str(markdown_path) + ".");
    }

    return 0;
}

with entry:__main__ {
    raise SystemExit(main(list(argv[1:])));
}
