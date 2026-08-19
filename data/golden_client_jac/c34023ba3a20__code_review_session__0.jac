node Profile {
    has display_name: str,
        bio: str = "";
}

# Protected (default) -- requires JWT.
walker get_profile {
    can fetch with Root entry {
        profiles = [-->][?:Profile];
        if profiles {
            p = profiles[0];
            report {"display_name": p.display_name, "bio": p.bio};
        } else {
            report {"error": "no profile"};
        }
    }
}

# Public -- no auth.
walker :pub health_check {
    can check with Root entry { report {"status": "ok"}; }
}
