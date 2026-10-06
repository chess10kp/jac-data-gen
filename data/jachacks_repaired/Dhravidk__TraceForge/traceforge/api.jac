import from traceforge.__init__ {
    project_identity,
}
import from traceforge.ingest {
    batch_catalog_summary,
    parse_batch_summary,
    sample_batch_summary,
    upload_batch_summary
}
import from traceforge.analysis {
    analyze_batch_summary,
    batch_overview_summary,
    cluster_view_summary,
    run_view_summary
}
import from traceforge.graph_build { invalidate_batch_graph }
import from traceforge.eval {
    compare_run_harness_summary,
    export_blinded_eval_summary,
    pack_run_summary,
    run_rigorous_eval_summary,
}
import from traceforge.llm_ops {
    compile_memory_patch_summary,
    diagnose_cluster_summary,
    diagnose_run_summary
}
import from traceforge.provider_config {
    provider_status_summary,
    save_provider_config_summary,
}
import from traceforge.reporting { export_report_summary }

walker:pub GetStatus {
    can get with Root entry {
        report {
            "project": project_identity(),
            "phase": "cli_first_beta",
            "message": "TraceForge ships a CLI-first graph-backed beta for coding-agent trajectory analysis, pack generation, and compare/export workflows.",
        };
    }
}

walker:pub UploadBatch {
    has filename: str = "";

    can run with Root entry {
        report upload_batch_summary(self.filename);
    }
}

walker:pub GetBatchCatalog {
    can run with Root entry {
        report batch_catalog_summary();
    }
}

walker:pub GetProviderStatus {
    can run with Root entry {
        report provider_status_summary();
    }
}

walker:pub SaveProviderConfig {
    has preferred_provider: str = "auto";
    has openai_api_key: str = "";
    has openai_model: str = "";
    has anthropic_api_key: str = "";
    has anthropic_model: str = "";
    has codex_model: str = "";
    has codex_cli_path: str = "";
    has clear_openai_key: bool = False;
    has clear_anthropic_key: bool = False;

    can run with Root entry {
        report save_provider_config_summary(
            self.preferred_provider,
            self.openai_api_key,
            self.openai_model,
            self.anthropic_api_key,
            self.anthropic_model,
            self.codex_model,
            self.codex_cli_path,
            self.clear_openai_key,
            self.clear_anthropic_key,
        );
    }
}

walker:pub LoadSampleBatch {
    has sample_name: str = "starter";

    can run with Root entry {
        report sample_batch_summary(self.sample_name);
    }
}

walker:pub ParseBatch {
    has batch_id: str;

    can run with Root entry {
        report parse_batch_summary(self.batch_id);
    }
}

walker:pub AnalyzeBatch {
    has batch_id: str;
    has force_rebuild: bool = False;

    can run with Root entry {
        report analyze_batch_summary(root, self.batch_id, self.force_rebuild);
    }
}

walker:pub InvalidateBatchGraph {
    has batch_id: str;

    can run with Root entry {
        report invalidate_batch_graph(root, self.batch_id);
    }
}

walker:pub GetBatchOverview {
    has batch_id: str;

    can run with Root entry {
        report batch_overview_summary(root, self.batch_id);
    }
}

walker:pub GetClusterView {
    has cluster_id: str;

    can run with Root entry {
        report cluster_view_summary(root, self.cluster_id);
    }
}

walker:pub GetRunView {
    has run_id: str;
    has batch_id: str = "";

    can run with Root entry {
        report run_view_summary(root, self.run_id, self.batch_id);
    }
}

walker:pub PackRun {
    has run_id: str;
    has batch_id: str = "";
    has mode: str = "structured";

    can run with Root entry {
        report pack_run_summary(root, self.run_id, self.batch_id, self.mode);
    }
}

walker:pub DiagnoseRun {
    has run_id: str;
    has batch_id: str = "";

    can run with Root entry {
        report diagnose_run_summary(root, self.run_id, self.batch_id);
    }
}

walker:pub DiagnoseCluster {
    has cluster_id: str;

    can run with Root entry {
        report diagnose_cluster_summary(root, self.cluster_id);
    }
}

walker:pub CompileMemoryPatch {
    has cluster_id: str;

    can run with Root entry {
        report compile_memory_patch_summary(root, self.cluster_id);
    }
}

walker:pub ExportBatchReport {
    has batch_id: str;

    can run with Root entry {
        report export_report_summary(root, self.batch_id);
    }
}

walker:pub ExportBlindedEvaluation {
    has batch_id: str;
    has limit: int = 10;
    has substantive_only: bool = True;
    has provider: str = "auto";
    has model: str = "";

    can run with Root entry {
        report export_blinded_eval_summary(root, self.batch_id, self.limit, self.substantive_only, self.provider, self.model);
    }
}

walker:pub CompareBaseline {
    has run_id: str;
    has batch_id: str = "";
    has provider: str = "auto";
    has model: str = "";

    can run with Root entry {
        report compare_run_harness_summary(root, self.run_id, self.batch_id, self.provider, self.model);
    }
}

walker:pub RunRigorousEvaluation {
    has batch_id: str;
    has provider: str = "auto";
    has model: str = "";
    has substantive_limit: int = 20;
    has startup_limit: int = 5;
    has annotation_path: str = "";

    can run with Root entry {
        report run_rigorous_eval_summary(
            root,
            self.batch_id,
            self.provider,
            self.model,
            self.substantive_limit,
            self.startup_limit,
            self.annotation_path,
        );
    }
}
