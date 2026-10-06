"""
main.jac — Nourish App entry point.
"""

import from services.nourish_api {
    NourishHub, Business, Shelter, Donation, Volunteer,
    DashboardStats, DonationInfo, ShelterInfo, DispatchResult, VolunteerInfo,
    get_dashboard, get_donations, get_shelters, get_volunteers,
    add_donation, run_dispatch, reset_ecosystem
}

import ".styles.global.css";

import from .index { ClientApp }

def:pub app() -> JsxElement {
    return <ClientApp />;
}
