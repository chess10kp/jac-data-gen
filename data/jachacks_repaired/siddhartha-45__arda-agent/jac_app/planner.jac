"""
Planner Agent - Breaks down complex queries into executable tasks
"""

import json;
import from tools.llm_tool { LLMTool }

walker PlanTasks {
    """
    Analyzes user query and creates a structured task plan
    """
    has query: str;
    has tasks: list = [];
    has task_count: int = 0;
    has llm_tool: any = None;

    def init {
        self.llm_tool = LLMTool();
    }

    can with Root entry {
        self.task_breakdown();
    }

    def task_breakdown {
        prompt = f"""
Analyze this research query and break it down into 3-5 concrete, executable tasks.

Query: {self.query}

For each task, provide:
1. Task description
2. Required tool (search, reasoning, analysis)
3. Priority (1-5, with 5 being highest)
4. Success criteria

Format as JSON list with fields: description, tool, priority, criteria
""";

        response = self.llm_tool.call(prompt);

        try {
            tasks_data = json.loads(response);
            for (i, task_data) in enumerate(tasks_data) {
                task_obj = {
                    'task_id': f'task_{i+1}',
                    'description': task_data.get('description', ''),
                    'tool': task_data.get('tool', 'reasoning'),
                    'priority': int(task_data.get('priority', 3)),
                    'criteria': task_data.get('criteria', ''),
                    'status': 'pending'
                };
                self.tasks.append(task_obj);
            }
        } except Exception {
            self.tasks = [
                {
                    'task_id': 'task_1',
                    'description': f'Research and analyze: {self.query}',
                    'tool': 'search',
                    'priority': 5,
                    'criteria': 'Gather comprehensive information',
                    'status': 'pending'
                }
            ];
        }
    }

    def generate_execution_plan {
        self.prioritize_tasks();

        plan = {
            'total_tasks': len(self.tasks),
            'tasks': self.tasks,
            'execution_order': [t['task_id'] for t in sorted(self.tasks, key=lambda (x: dict) { -(x['priority'] as int) })]
        };

        report f"Plan generated: {len(self.tasks)} tasks";
    }

    def prioritize_tasks {
        self.tasks = sorted(self.tasks, key=lambda (x: dict) { -(x['priority'] as int) });
    }
}
