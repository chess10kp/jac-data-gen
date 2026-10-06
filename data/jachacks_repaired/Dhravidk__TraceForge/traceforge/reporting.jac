import from pathlib { Path }
import from traceforge.parser { truncate_text }
import from traceforge.analysis {
    batch_overview_summary,
    cluster_view_summary,
    run_view_summary
}
import from traceforge.eval { compare_run_harness_summary }
import from traceforge.llm_ops { compile_memory_patch_summary }

def export_report_summary(root_node: any, batch_id: str) -> dict[str, any] {
    overview = batch_overview_summary(root_node, batch_id);
    if overview["status"] == "missing" {
        return {
            "batch_id": batch_id,
            "status": "missing",
            "message": "Batch was not found.",
        };
    }

    sorted_families = sorted(
        overview["family_counts"].items(),
        key=lambda (item: any) -> any { (-item[1], item[0]) },
    );
    lead_family = "UNKNOWN";
    if len(sorted_families) > 0 {
        lead_family = sorted_families[0][0];
    }
    highlight_run = {};
    has_highlight_run = False;
    if len(overview["runs"]) > 0 {
        highlight_run = overview["runs"][0];
        has_highlight_run = True;
    }

    lines: list[str] = [
        "# TraceForge Batch Report",
        "",
        f"- Batch ID: `{batch_id}`",
        f"- Run count: {overview['run_count']}",
        f"- Cluster count: {overview['cluster_count']}",
        f"- Dominant failure family: {lead_family}",
        "",
        "## Demo Highlights",
        "",
        "TraceForge compiles coding-agent trajectories into a Jac graph, groups recurring failure motifs, localizes likely critical steps, and synthesizes reusable AGENTS.md memory patches.",
        "",
        "### Batch Snapshot",
        "",
        f"- Active batch: `{batch_id}`",
        f"- Runs analyzed: {overview['run_count']}",
        f"- Clusters formed: {overview['cluster_count']}",
        f"- Leading failure family: {lead_family}",
        "",
        "## Failure Families",
    ];

    for family in sorted(overview["family_counts"]) {
        lines.append(f"- {family}: {overview['family_counts'][family]}");
    }

    if overview["top_files"] {
        lines.extend([
            "",
            "## Frequent Artifacts",
            "",
            "### Top Files",
        ]);
        for item in overview["top_files"] {
            lines.append(f"- {item[0]} ({item[1]})");
        }
    }

    if overview["top_errors"] {
        lines.extend([
            "",
            "### Top Error Keywords",
        ]);
        for item in overview["top_errors"] {
            lines.append(f"- {item[0]} ({item[1]})");
        }
    }

    if overview["top_tests"] {
        lines.extend([
            "",
            "### Top Tests",
        ]);
        for item in overview["top_tests"] {
            lines.append(f"- {item[0]} ({item[1]})");
        }
    }

    lines.extend([
        "",
        "## Clusters",
    ]);

    for cluster in overview["clusters"] {
        detail = cluster_view_summary(root_node, cluster["cluster_id"]);
        patch = compile_memory_patch_summary(root_node, cluster["cluster_id"]);
        patch_mode = "deterministic";
        if patch["llm_used"] {
            patch_mode = "typed_llm";
        }
        lines.append(f"### {detail['label']}");
        lines.append("");
        lines.append(f"- Cluster ID: `{detail['cluster_id']}`");
        lines.append(f"- Failure class: {detail['failure_class']}");
        lines.append(f"- Size: {detail['size']}");
        lines.append(f"- Medoid run: `{detail['medoid_run_id']}`");
        lines.append(f"- Stored patch count: {detail['stored_patch_count']}");
        lines.append(f"- Patch synthesis mode: {patch_mode}");
        if detail["recurring_signals"] {
            lines.append("- Recurring signals:");
            for signal in detail["recurring_signals"] {
                lines.append(f"  - {signal}");
            }
        }
        if detail["recurring_files"] {
            lines.append("- Recurring files:");
            for item in detail["recurring_files"] {
                lines.append(f"  - {item[0]} ({item[1]})");
            }
        }
        if detail["recurring_errors"] {
            lines.append("- Recurring errors:");
            for item in detail["recurring_errors"] {
                lines.append(f"  - {item[0]} ({item[1]})");
            }
        }
        if detail["recurring_tests"] {
            lines.append("- Recurring tests:");
            for item in detail["recurring_tests"] {
                lines.append(f"  - {item[0]} ({item[1]})");
            }
        }
        if detail["representative_runs"] {
            lines.append("- Representative runs:");
            run_counter = 0;
            for run_item in detail["representative_runs"] {
                if run_counter >= 3 {
                    break;
                }
                lines.append(f"  - {run_item['run_id']}: critical step {run_item['critical_step_idx']} | {run_item['summary']}");
                run_counter += 1;
            }
        }
        lines.append("");
        lines.append("#### AGENTS.md Patch");
        lines.append("");
        lines.append(f"- Summary: {patch['summary']}");
        lines.append(f"- Stored in graph: {patch['stored_in_graph']}");
        lines.append(f"- Patch ID: `{patch['stored_patch_id']}`");
        lines.append("");
        lines.append("```diff");
        lines.append(str(patch["diff_text"]));
        lines.append("```");
        lines.append("");
    }

    representative_run_ids: list[str] = [];
    if has_highlight_run {
        representative_run_ids.append(str(highlight_run["run_id"]));
    }
    for cluster in overview["clusters"] {
        medoid_run_id = str(cluster["medoid_run_id"]);
        if medoid_run_id and medoid_run_id not in representative_run_ids {
            representative_run_ids.append(medoid_run_id);
        }
        if len(representative_run_ids) >= 6 {
            break;
        }
    }

    lines.extend([
        "## Representative Runs",
        "",
        f"- Selected runs shown: {len(representative_run_ids)} of {overview['run_count']}",
        "",
    ]);

    for run_id in representative_run_ids {
        run_detail = run_view_summary(root_node, run_id, batch_id);
        if run_detail["status"] == "missing" {
            continue;
        }
        run_item = {
            "run_id": run_detail["run_id"],
            "task_title": run_detail["task_title"],
            "primary_failure": run_detail["primary_failure"],
            "critical_step_idx": run_detail["critical_step_idx"],
            "summary": run_detail["summary"],
        };
        lines.append(f"### {run_item['run_id']}");
        lines.append("");
        lines.append(f"- Task: {run_item['task_title']}");
        lines.append(f"- Primary failure: {run_item['primary_failure']}");
        lines.append(f"- Critical step: {run_item['critical_step_idx']}");
        lines.append(f"- Summary: {run_item['summary']}");
        lines.append(f"- Source path: `{run_detail['source_path']}`");
        if run_detail["critical_evidence_window"] {
            lines.append("- Critical evidence window:");
            for step in run_detail["critical_evidence_window"] {
                lines.append(f"  - Step {step['idx']} [{step['phase']}]: {step['excerpt']}");
            }
        }
        lines.append("");
    }

    lines.extend([
        "## Baseline Comparison Snapshot",
        "",
    ]);

    if has_highlight_run {
        comparison = compare_run_harness_summary(root_node, highlight_run["run_id"], batch_id);
        lines.append(f"### Run `{highlight_run['run_id']}`");
        lines.append("");
        lines.append(f"- Comparison mode: {comparison['comparison_mode']}");
        lines.append("- Raw baseline diagnosis:");
        lines.append(f"  - {comparison['baseline']['diagnosis']}");
        lines.append(f"  - Baseline mode: {comparison['baseline']['mode']}");
        lines.append(f"  - Specificity: {comparison['baseline']['specificity']}");
        lines.append(f"  - Estimated input size: {comparison['baseline']['pack_token_estimate']} tokens");
        if comparison["baseline"]["blind_spots"] {
            lines.append("  - Blind spots:");
            for item in comparison["baseline"]["blind_spots"] {
                lines.append(f"    - {item}");
            }
        }
        lines.append("- Structured diagnosis:");
        lines.append(f"  - Structured mode: {comparison['structured']['mode']}");
        lines.append(f"  - Failure class: {comparison['structured']['failure_class']}");
        lines.append(f"  - Critical step: {comparison['structured']['critical_step_idx']}");
        lines.append(f"  - Specificity: {comparison['structured']['specificity']}");
        lines.append(f"  - Estimated input size: {comparison['structured']['pack_token_estimate']} tokens");
        lines.append(f"  - Why better: {comparison['structured']['why_better']}");
        if comparison["structured"]["support_points"] {
            lines.append("  - Support points:");
            for item in comparison["structured"]["support_points"] {
                lines.append(f"    - {item}");
            }
        }
        if comparison["structured"]["evidence_window"] {
            lines.append("  - Evidence window:");
            for step in comparison["structured"]["evidence_window"] {
                lines.append(f"    - Step {step['idx']} [{step['phase']}]: {step['excerpt']}");
            }
        }
        lines.append("- Verifier:");
        lines.append(f"  - Winner: {comparison['verifier']['winner']}");
        lines.append(f"  - Rationale: {comparison['verifier']['rationale']}");
    } else {
        lines.append("No runs were available for comparison.");
    }

    lines.extend([
        "",
        "## Demo Talking Points",
        "",
        "- Open the batch overview first to show that the failures are grouped rather than shown as raw logs.",
        "- Jump into the leading cluster to show recurring signals, the medoid, and the generated AGENTS.md patch.",
        "- Open a representative run and point to the highlighted critical step window.",
        "- Close on the fair comparison to show the same-schema raw transcript arm versus TraceForge retrieval, then read the verifier verdict.",
    ]);

    export_dir = Path("exports");
    export_dir.mkdir(exist_ok=True);
    export_path = export_dir.joinpath(batch_id + ".md");
    export_text = "\n".join(lines).strip() + "\n";
    export_path.write_text(export_text, encoding="utf-8");
    preview_text = truncate_text(export_text, 1200);
    return {
        "batch_id": batch_id,
        "status": "exported",
        "path": str(export_path),
        "cluster_count": overview["cluster_count"],
        "run_count": overview["run_count"],
        "preview": preview_text,
    };
}
