"""Documents page — document upload, ingestion status, and classification results."""

import from graph.walkers.intake.document_ingest { DocumentIngest }
import from graph.walkers.intake.document_classify { DocumentClassify }


def:pub DocumentsPage() -> JsxElement {
    has documents: list = [];
    has loading: bool = True;
    has uploading: bool = False;

    async can with entry {
        loading = False;
    }

    return (
        <div className="documents-page">
            <div
                style={{"display": "flex", "align-items": "center", "justify-content": "space-between", "margin-bottom": "24px"}}
            >
                <h2 style={{"margin": "0", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>
                    Documents
                </h2>
                <button
                    style={{"background": "#3b82f6", "color": "white", "border": "none", "border-radius": "6px", "padding": "8px 16px", "font-size": "14px", "cursor": "pointer"}}
                >
                    Upload Document
                </button>
            </div>
            <div
                style={{"background": "white", "border-radius": "8px", "padding": "32px", "text-align": "center", "box-shadow": "0 1px 3px rgba(0,0,0,.1)", "border": "2px dashed #e2e8f0", "margin-bottom": "24px"}}
            >
                <p style={{"color": "#64748b", "font-size": "14px", "margin": "0"}}>
                    Drop EOBs, MSNs, bills, or legal documents here
                </p>
                <p style={{"color": "#94a3b8", "font-size": "12px", "margin": "8px 0 0"}}>
                    PDF, PNG, JPG supported
                </p>
            </div>
            {loading and <p style={{"color": "#64748b"}}>Loading documents...</p>}
            {not loading
                and len(documents) == 0
                and (
                    <p style={{"color": "#64748b", "font-size": "14px"}}>
                        No documents uploaded yet.
                    </p>
                )}
        </div>
    );
}
