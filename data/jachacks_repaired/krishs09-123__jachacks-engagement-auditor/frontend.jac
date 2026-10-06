import from "@jac/runtime" {
    Route as RuntimeRoute,
    Router as RuntimeRouter,
    Routes as RuntimeRoutes,
}
import from .pages.FlairLogin { FlairLoginPage }
import from .pages.AuditInput { AuditInputPage }
import from .pages.Start { StartPage }
import from .pages.Loading { LoadingPage }
import from .pages.ReportOverview { ReportOverviewPage }
import from .pages.FlairPillar { FlairPillarPage }
import from .pages.AuditList { AuditListPage }
import from .pages.EvidenceDetail { EvidenceDetailPage }

import "./styles/main.css";

def:pub app() -> JsxElement {
    return <RuntimeRouter>
        <RuntimeRoutes>
            <RuntimeRoute path="/" element={<FlairLoginPage />} />
            <RuntimeRoute path="/login" element={<FlairLoginPage />} />
            <RuntimeRoute path="/signup" element={<FlairLoginPage initialMode="signup" />} />
            <RuntimeRoute path="/audit" element={<AuditInputPage />} />
            <RuntimeRoute path="/start" element={<StartPage />} />
            <RuntimeRoute path="/loading" element={<LoadingPage />} />
            <RuntimeRoute path="/report" element={<ReportOverviewPage />} />
            <RuntimeRoute path="/report/:pillar" element={<FlairPillarPage />} />
            <RuntimeRoute path="/audits" element={<AuditListPage />} />
            <RuntimeRoute path="/evidence/:id" element={<EvidenceDetailPage />} />
        </RuntimeRoutes>
    </RuntimeRouter>;
}
