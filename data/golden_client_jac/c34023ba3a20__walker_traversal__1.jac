# Protected (default) -- requires JWT token
walker get_profile {
    can fetch with Root entry { report [-->]; }
}

# Public -- no authentication required
walker :pub health_check {
    can check with Root entry { report {"status": "ok"}; }
}

# Private -- requires authentication, per-user isolated
walker :priv internal_process {
    can run with Root entry { }
}
