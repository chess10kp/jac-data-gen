cl import from react { useState }

cl def:pub app -> JsxElement {
    (tasks, set_tasks) = useState([]);
    (task_text, set_task_text) = useState("");
    (filter, set_filter) = useState("all");

    return
        <div class="container">
            <h1>Day Planner</h1>
            <div class="filters">
                <button onClick={lambda { set_filter("all"); }}>All</button>
                <button onClick={lambda { set_filter("active"); }}>Active</button>
                <button onClick={lambda { set_filter("done"); }}>Done</button>
            </div>
            {[
                <div key={jid(t)} class="task-item">{t.title}</div>
                for t in tasks
                if filter == "all"
                    or (filter == "active" and not t.done)
                    or (filter == "done" and t.done)
            ]}
        </div>;
}
