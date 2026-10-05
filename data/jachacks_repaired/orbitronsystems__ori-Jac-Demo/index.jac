import from .pages.WelcomePage { page as WelcomePage }
import from .pages.OnboardingPage { page as OnboardingPage }
import from .pages.DashboardPage { page as DashboardPage }
import from "@jac/runtime" { Router, Routes, Route, Navigate }

# ORBITRON ERP Platform Router
def:pub ClientApp() -> JsxElement {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<WelcomePage />} />
                <Route path="/onboarding" element={<OnboardingPage />} />
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="*" element={<Navigate to="/" replace={True} />} />
            </Routes>
        </Router>
    );
}
