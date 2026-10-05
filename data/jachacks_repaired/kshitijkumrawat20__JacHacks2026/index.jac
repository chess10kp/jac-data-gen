import from .pages.LoginPage { page as LoginPage }
import from .pages.DashboardPage { page as DashboardPage }
import from .pages.GoalWorkspacePage { page as GoalWorkspacePage }
import from .pages.AgentActivityPage { page as AgentActivityPage }
import from .pages.AnalyticsPage { page as AnalyticsPage }
import from .pages.MemoryTimelinePage { page as MemoryTimelinePage }
import from .pages.OpportunityHubPage { page as OpportunityHubPage }
import from .pages.SettingsPage { page as SettingsPage }
import from "@jac/runtime" { Router, Routes, Route, Navigate }

def:pub ClientApp() -> JsxElement {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<Navigate to="/login" replace={True} />} />
                <Route path="/login" element={<LoginPage />} />
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/goals" element={<GoalWorkspacePage />} />
                <Route path="/agents" element={<AgentActivityPage />} />
                <Route path="/analytics" element={<AnalyticsPage />} />
                <Route path="/memory" element={<MemoryTimelinePage />} />
                <Route path="/opportunities" element={<OpportunityHubPage />} />
                <Route path="/settings" element={<SettingsPage />} />
            </Routes>
        </Router>
    );
}
