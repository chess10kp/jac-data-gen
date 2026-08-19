walker find_profile {
    has target_id: str = "";
    can run with Root entry {
        target = jobj(self.target_id);
        visit [target];
    }
}
