import from pathlib { Path }
import from zipfile { ZipFile }
import from traceforge.parser { parse_run, path_run_stem }

glob SAMPLE_ROOT: str = "demo_runs";
glob UPLOAD_ROOT: str = "uploads";

def _normalize_batch_name(name: str) -> str {
    if name.endswith("_batch") {
        return name.removesuffix("_batch");
    }
    return name;
}

def _batch_name_from_id(batch_id: str) -> str {
    if batch_id.startswith("sample-") {
        return batch_id.removeprefix("sample-");
    }
    if batch_id.startswith("upload-") {
        return batch_id.removeprefix("upload-");
    }
    return batch_id;
}

def _batch_kind(batch_id: str) -> str {
    if batch_id.startswith("sample-") {
        return "sample";
    }
    if batch_id.startswith("upload-") {
        return "upload";
    }
    return "unknown";
}

def _traj_files_in_dir(batch_dir: Path) -> list[str] {
    if not batch_dir.exists() or not batch_dir.is_dir() {
        return [];
    }
    return [str(path) for path in sorted(batch_dir.rglob("*.traj.json")) if path.is_file()];
}

def sample_batch_path(name: str = "starter") -> str {
    return f"{SAMPLE_ROOT}/{name}_batch";
}

def _upload_batch_path(name: str) -> str {
    direct = Path(UPLOAD_ROOT) / name;
    if direct.exists() and direct.is_dir() {
        return str(direct);
    }
    suffixed = Path(UPLOAD_ROOT) / (name + "_batch");
    if suffixed.exists() and suffixed.is_dir() {
        return str(suffixed);
    }
    return str(direct);
}

def batch_path(batch_id: str) -> str {
    name = _batch_name_from_id(batch_id);
    kind = _batch_kind(batch_id);
    if kind == "sample" {
        return sample_batch_path(name);
    }
    if kind == "upload" {
        return _upload_batch_path(name);
    }
    return "";
}

def batch_files(batch_id: str) -> list[str] {
    batch_dir = batch_path(batch_id);
    if not batch_dir {
        return [];
    }
    return _traj_files_in_dir(Path(batch_dir));
}

def sample_batch_files(name: str = "starter") -> list[str] {
    return batch_files("sample-" + name);
}

def sample_file_run_id(path: str) -> str {
    return path_run_stem(path);
}

def _batch_run_ids(files: list[str]) -> list[str] {
    return [sample_file_run_id(path) for path in files];
}

def _build_batch_summary(batch_id: str, source_path: str, source_format: str = "mini-swe-agent") -> dict[str, any] {
    files = batch_files(batch_id);
    run_ids = _batch_run_ids(files);
    return {
        "batch_id": batch_id,
        "name": _batch_name_from_id(batch_id),
        "source_format": source_format,
        "run_count": len(files),
        "run_ids": run_ids,
        "sample_path": source_path,
        "status": ("ready") if files else ("missing"),
        "next_step": "Use ParseBatch, AnalyzeBatch, or GetRunView on one of the discovered runs.",
    };
}

def sample_batch_summary(name: str = "starter") -> dict[str, any] {
    batch_id = "sample-" + name;
    return _build_batch_summary(batch_id, sample_batch_path(name));
}

def available_upload_batch_ids() -> list[str] {
    root_dir = Path(UPLOAD_ROOT);
    if not root_dir.exists() or not root_dir.is_dir() {
        return [];
    }
    batch_ids: list[str] = [];
    for path in sorted(root_dir.iterdir()) {
        if not path.is_dir() {
            continue;
        }
        if _traj_files_in_dir(path) {
            batch_ids.append("upload-" + _normalize_batch_name(path.name));
        }
    }
    return batch_ids;
}

def _resolve_upload_dir(filename: str) -> str {
    direct = Path(filename);
    candidates = [
        direct,
        Path(UPLOAD_ROOT) / filename,
        Path(UPLOAD_ROOT) / (filename + "_batch"),
    ];
    for candidate in candidates {
        if candidate.exists() and candidate.is_dir() and _traj_files_in_dir(candidate) {
            return str(candidate);
        }
    }
    return "";
}

def _path_under_upload_root(path: str) -> bool {
    try {
        return str(Path(path).resolve()).startswith(str(Path(UPLOAD_ROOT).resolve()));
    } except Exception {
        return False;
    }
}

def _managed_upload_alias_name(path: str) -> str {
    return _normalize_batch_name(Path(path).name);
}

def _ensure_managed_upload_dir(path: str) -> dict[str, str] {
    resolved_path = str(Path(path).resolve());
    if _path_under_upload_root(resolved_path) {
        return {
            "resolved_path": resolved_path,
            "managed_path": path,
            "managed_name": _managed_upload_alias_name(path),
            "managed": "false",
        };
    }

    root_dir = Path(UPLOAD_ROOT);
    root_dir.mkdir(parents=True, exist_ok=True);
    base_name = _managed_upload_alias_name(resolved_path);
    candidate = root_dir / base_name;
    suffix = 2;
    while candidate.exists() and not str(candidate.resolve()) == resolved_path {
        candidate = root_dir / (base_name + "_" + str(suffix));
        suffix += 1;
    }

    if not candidate.exists() {
        candidate.symlink_to(resolved_path, target_is_directory=True);
    }
    return {
        "resolved_path": resolved_path,
        "managed_path": str(candidate),
        "managed_name": _normalize_batch_name(candidate.name),
        "managed": "true",
    };
}

def _resolve_upload_archive(filename: str) -> str {
    direct = Path(filename);
    candidates = [
        direct,
        Path(UPLOAD_ROOT) / filename,
    ];
    if not str(direct).lower().endswith(".zip") {
        candidates.append(Path(str(direct) + ".zip"));
        candidates.append(Path(UPLOAD_ROOT) / (filename + ".zip"));
    }
    for candidate in candidates {
        if candidate.exists() and candidate.is_file() and str(candidate).lower().endswith(".zip") {
            return str(candidate);
        }
    }
    return "";
}

def _extract_upload_archive(archive_path: str) -> str {
    archive = Path(archive_path);
    target_dir = Path(UPLOAD_ROOT) / archive.stem;
    target_dir.mkdir(parents=True, exist_ok=True);
    zip_file = ZipFile(str(archive), "r");
    zip_file.extractall(str(target_dir));
    zip_file.close();
    return str(target_dir);
}

def upload_batch_summary(filename: str = "") -> dict[str, any] {
    available = available_upload_batch_ids();
    if not filename {
        return {
            "batch_id": "",
            "status": "awaiting_folder",
            "message": "Provide a folder name, folder path, or zip archive under uploads/ that contains *.traj.json files.",
            "available_uploads": available,
        };
    }

    resolved = _resolve_upload_dir(filename);
    resolved_archive = "";
    ingest_mode = "folder";
    if not resolved {
        resolved_archive = _resolve_upload_archive(filename);
        if resolved_archive {
            resolved = _extract_upload_archive(resolved_archive);
            ingest_mode = "zip";
        }
    }
    if not resolved {
        return {
            "batch_id": "",
            "filename": filename,
            "status": "missing",
            "message": "No local upload folder or zip archive with *.traj.json files was found for that name or path.",
            "available_uploads": available,
        };
    }

    managed = _ensure_managed_upload_dir(resolved);
    batch_name = managed["managed_name"];
    batch_id = "upload-" + batch_name;
    summary = _build_batch_summary(batch_id, managed["managed_path"]);
    summary["resolved_path"] = managed["managed_path"];
    summary["source_path"] = managed["resolved_path"];
    summary["managed_alias"] = managed["managed_path"];
    summary["managed_alias_created"] = managed["managed"] == "true";
    summary["ingest_mode"] = ingest_mode;
    if resolved_archive {
        summary["resolved_archive"] = resolved_archive;
    }
    summary["available_uploads"] = available_upload_batch_ids();
    return summary;
}

def batch_summary(batch_id: str) -> dict[str, any] {
    if _batch_kind(batch_id) == "sample" {
        return sample_batch_summary(_batch_name_from_id(batch_id));
    }
    if _batch_kind(batch_id) == "upload" {
        return upload_batch_summary(batch_path(batch_id));
    }
    return {
        "batch_id": batch_id,
        "status": "missing",
        "message": "Batch ID was not recognized.",
    };
}

def batch_catalog_summary() -> dict[str, any] {
    entries: list[dict[str, any]] = [];
    for batch_id in all_known_batch_ids() {
        summary = batch_summary(batch_id);
        entries.append(
            {
                "batch_id": summary["batch_id"],
                "name": summary["name"],
                "source_format": summary["source_format"],
                "run_count": summary["run_count"],
                "status": summary["status"],
                "path": summary.get("resolved_path") or summary.get("sample_path") or "",
                "kind": _batch_kind(batch_id),
            }
        );
    }
    return {
        "status": "ready" if entries else "missing",
        "batches": entries,
        "batch_count": len(entries),
    };
}

def parse_batch_summary(batch_id: str) -> dict[str, any] {
    files = batch_files(batch_id);
    if files {
        parsed_runs = [];
        for path in files {
            run = parse_run(path);
            parsed_runs.append(
                {
                    "run_id": run.run_id,
                    "instance_id": run.instance_id,
                    "task_title": run.task_title,
                    "step_count": len(run.steps),
                    "turn_count": len(run.turns),
                    "source_path": run.source_path,
                    "metadata": run.metadata,
                }
            );
        }
        return {
            "batch_id": batch_id,
            "status": "parsed",
            "run_count": len(parsed_runs),
            "runs": parsed_runs,
        };
    }
    return {
        "batch_id": batch_id,
        "status": "missing",
        "message": "No trajectories were found for that batch.",
    };
}

def all_known_batch_ids() -> list[str] {
    sample_batches: list[str] = [];
    sample_root = Path(SAMPLE_ROOT);
    if sample_root.exists() and sample_root.is_dir() {
        for path in sorted(sample_root.iterdir()) {
            if not path.is_dir() {
                continue;
            }
            if not _traj_files_in_dir(path) {
                continue;
            }
            sample_batches.append("sample-" + _normalize_batch_name(path.name));
        }
    }
    return sample_batches + available_upload_batch_ids();
}

def batch_ids_for_run(run_id: str) -> list[str] {
    batch_ids: list[str] = [];
    for batch_id in all_known_batch_ids() {
        for path in batch_files(batch_id) {
            if sample_file_run_id(path) == run_id {
                batch_ids.append(batch_id);
                break;
            }
        }
    }
    return batch_ids;
}

def batch_id_for_run(run_id: str) -> str {
    matches = batch_ids_for_run(run_id);
    if len(matches) == 1 {
        return matches[0];
    }
    return "";
}

def run_source_path(run_id: str, batch_id: str = "") -> str {
    chosen_batch_id = batch_id;
    if not chosen_batch_id {
        chosen_batch_id = batch_id_for_run(run_id);
    }
    if not chosen_batch_id {
        return "";
    }
    for path in batch_files(chosen_batch_id) {
        if sample_file_run_id(path) == run_id {
            return path;
        }
    }
    return "";
}
