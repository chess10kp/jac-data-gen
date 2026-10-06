"""Legal & Estate page — POA, will, HIPAA auth, and beneficiary status."""

import from graph.walkers.legal.legal_doc_scanner { LegalDocScanner }
import from graph.walkers.legal.expiry_monitor { ExpiryMonitor }
import from graph.walkers.legal.beneficiary_auditor { BeneficiaryAuditor }


def:pub LegalPage() -> JsxElement {
    has legal_docs: list = [];
    has beneficiaries: list = [];
    has loading: bool = True;

    async can with entry {
        loading = False;
    }

    return (
        <div className="legal-page">
            <h2 style={{"margin": "0 0 24px", "font-size": "24px", "font-weight": "700", "color": "#1e293b"}}>
                Legal & Estate
            </h2>
            <div
                style={{"display": "grid", "grid-template-columns": "1fr 1fr", "gap": "16px", "margin-bottom": "24px"}}
            >
                <div
                    style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                >
                    <h3 style={{"margin": "0 0 16px", "font-size": "16px", "font-weight": "600"}}>
                        Legal Documents
                    </h3>
                    {loading
                        and <p style={{"color": "#64748b", "font-size": "14px"}}>Loading...</p>}
                    {not loading
                        and len(legal_docs) == 0
                        and (
                            <p style={{"color": "#64748b", "font-size": "14px"}}>
                                No legal documents on file. Upload a will, POA, or HIPAA authorization.
                            </p>
                        )}
                </div>
                <div
                    style={{"background": "white", "border-radius": "8px", "padding": "20px", "box-shadow": "0 1px 3px rgba(0,0,0,.1)"}}
                >
                    <h3 style={{"margin": "0 0 16px", "font-size": "16px", "font-weight": "600"}}>
                        Beneficiary Designations
                    </h3>
                    {loading
                        and <p style={{"color": "#64748b", "font-size": "14px"}}>Loading...</p>}
                    {not loading
                        and len(beneficiaries) == 0
                        and (
                            <p style={{"color": "#64748b", "font-size": "14px"}}>
                                No beneficiary designations on file.
                            </p>
                        )}
                </div>
            </div>
            <div
                style={{"background": "#fef3c7", "border": "1px solid #fcd34d", "border-radius": "8px", "padding": "16px"}}
            >
                <p style={{"margin": "0", "font-size": "14px", "color": "#92400e", "font-weight": "600"}}>
                    Important: Estate Planning
                </p>
                <p style={{"margin": "8px 0 0", "font-size": "14px", "color": "#92400e"}}>
                    Review and update your POA, healthcare proxy, and beneficiary designations regularly.
                </p>
            </div>
        </div>
    );
}
