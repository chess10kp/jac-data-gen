import from datetime { datetime }

walker:pub get_tasks {
    can fetch with Root entry {
        report [-->][?:Task];  # Reports typed Task nodes directly
    }
}

walker:pub add_task {
    has title: str;

    can create with Root entry {
        new_task = Task(
            title=self.title,
            created_at=datetime.now().isoformat()
        );
        root ++> new_task;
        report new_task;  # Report the typed Task node
    }
}

walker:pub toggle_task {
    has task_id: str;

    can toggle with Root entry {
        for task in [-->][?:Task] {
            if jid(task) == self.task_id {
                task.completed = not task.completed;
                report task;  # Report the updated Task node
                return;
            }
        }
        report {"error": f"No task found with id {self.task_id}"};
    }
}

walker:pub delete_task {
    has task_id: str;

    can remove with Root entry {
        for task in [-->][?:Task] {
            if jid(task) == self.task_id {
                del task;
                report {"success": True};
                return;
            }
        }
        report {"success": False, "error": f"No task found with id {self.task_id}"};
    }
}
