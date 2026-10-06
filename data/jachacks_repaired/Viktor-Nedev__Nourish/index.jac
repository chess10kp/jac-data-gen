import from "@jac/runtime" { Router, Routes, Route, Navigate }
import from .pages.LandingPage { LandingPage }
import from .pages.AuthPage { AuthPage }
import from .pages.OnboardingPage { OnboardingPage }
import from .pages.UserDashboard { UserDashboard }
import from .pages.OrgDashboard { OrgDashboard }
import from .pages.MapPage { MapPage }
import from .pages.DonationFeed { DonationFeed }
import from .pages.CreateDonation { CreateDonation }
import from .pages.DonationDetails { DonationDetails }
import from .pages.RequestsFeed { RequestsFeed }
import from .pages.CreateRequest { CreateRequest }
import from .pages.RequestDetails { RequestDetails }
import from .pages.EventsList { EventsList }
import from .pages.CreateEvent { CreateEvent }
import from .pages.EventDetails { EventDetails }
import from .pages.AIInsights { AIInsights }
import from .pages.AIAlerts { AIAlerts }
import from .pages.ProfilePage { ProfilePage }
import from .pages.SettingsPage { SettingsPage }

def:pub ClientApp() -> JsxElement {
    return (
        <Router>
            <Routes>
                <Route path="/" element={<LandingPage />} />
                <Route path="/auth" element={<AuthPage />} />
                <Route path="/onboarding" element={<OnboardingPage />} />
                <Route path="/map" element={<MapPage />} />
                <Route path="/donations/feed" element={<DonationFeed />} />
                <Route path="/donations/new" element={<CreateDonation />} />
                <Route path="/donations/:id" element={<DonationDetails />} />
                <Route path="/requests" element={<RequestsFeed />} />
                <Route path="/requests/new" element={<CreateRequest />} />
                <Route path="/requests/:id" element={<RequestDetails />} />
                <Route path="/events" element={<EventsList />} />
                <Route path="/events/new" element={<CreateEvent />} />
                <Route path="/events/:id" element={<EventDetails />} />
                <Route path="/dashboard/user" element={<UserDashboard />} />
                <Route path="/dashboard/org" element={<OrgDashboard />} />
                <Route path="/ai/insights" element={<AIInsights />} />
                <Route path="/ai/alerts" element={<AIAlerts />} />
                <Route path="/profile" element={<ProfilePage />} />
                <Route path="/settings" element={<SettingsPage />} />
                <Route path="/login" element={<Navigate to="/auth" replace={True} />} />
                <Route path="/dashboard" element={<Navigate to="/dashboard/user" replace={True} />} />
            </Routes>
        </Router>
    );
}
