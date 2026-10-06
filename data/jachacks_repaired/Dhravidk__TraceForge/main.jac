import traceforge.__init__;
import traceforge.schema;
import traceforge.ingest;
import traceforge.parser;
import traceforge.features;
import traceforge.clustering;
import traceforge.critical;
import traceforge.graph_build;
import traceforge.analysis;
import traceforge.llm_ops;
import traceforge.eval;
import traceforge.reporting;
import traceforge.provider_config;
import traceforge.api;
import traceforge.ui;
import from traceforge.ui { app as TraceForgeApp }

def:pub app() -> JsxElement {
    return <TraceForgeApp />;
}

with entry {}
