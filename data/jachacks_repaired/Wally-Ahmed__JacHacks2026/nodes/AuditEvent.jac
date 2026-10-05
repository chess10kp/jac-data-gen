import from datetime { datetime }

node AuditEvent {
    has audit_id: str = "";
    has actor: str = "system";
    has action: str = "";
    has target_type: str = "";
    has target_id: str = "";
    has result: str = "ok";
    has notes: str = "";
    has created_at: str = "";

    def postinit {
        if not self.created_at {
            self.created_at = datetime.now().isoformat();
        }
    }
}
