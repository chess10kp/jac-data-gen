walker DeleteTask {
    has task_id: str;

    can search with Root entry { visit [-->]; }

    can remove with Task entry {
        if jid(here) == self.task_id {
            del here;
            report {"deleted": self.task_id};
            disengage;
        }
    }
}
