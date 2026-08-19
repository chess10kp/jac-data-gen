import from datetime { datetime }

node Task {
    has title: str;
    has completed: bool = False;
    has created_at: str by postinit;

    def postinit {
        self.created_at = datetime.now().isoformat();
    }
}
