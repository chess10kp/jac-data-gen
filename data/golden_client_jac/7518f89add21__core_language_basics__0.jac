cl import from react { useState }

    cl def:pub app -> JsxElement {
        (tasks, set_tasks) = useState([]);
        (task_text, set_task_text) = useState("");

        # Use set_tasks([...]) and set_task_text("...") to update state
    }
