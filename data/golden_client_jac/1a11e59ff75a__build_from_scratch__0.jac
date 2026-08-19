walker get_all_profiles {
    has results: list = [];
    can gather with Profile entry {
        report here.to_user_view();
    }
    can deliver with Root exit {
        report self.results;
    }
}
