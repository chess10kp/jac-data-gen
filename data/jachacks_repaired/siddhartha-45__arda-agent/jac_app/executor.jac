"""
Executor Agent - Performs tasks using available tools
"""

import json;
import time;
import from tools.search_tool { SearchTool }
import from tools.llm_tool { LLMTool }

walker ExecuteTasks {
    """
    Executes planned tasks and generates analyses
    """
    has tasks: list;
    has results: list = [];
    has search_tool: any = None;
    has llm_tool: any = None;
    has max_retries: int = 3;
    has retry_count: dict = {};

    def init {
        self.search_tool = SearchTool();
        self.llm_tool = LLMTool();
    }

    can with Root entry {
        self.execute_all();
    }

    def execute_all {
        for task in self.tasks {
            self.route_task(task);
        }
    }

    def route_task(task: dict) {
        tool = task.get('tool', 'reasoning');

        if tool == 'search' {
            self.search_task(task);
        } elif tool == 'reasoning' {
            self.reasoning_task(task);
        } else {
            self.reasoning_task(task);
        }
    }

    def search_task(task: dict) {
        task_id = task.get('task_id');
        description = task.get('description');

        try {
            search_results = self.search_tool.search(description, num_results=5);

            analysis_prompt = f"""
Analyze these search results and provide a comprehensive analysis.

Query: {description}

Results:
{json.dumps(search_results, indent=2)}

Provide a detailed analysis covering:
1. Key findings
2. Relevant statistics
3. Expert opinions found
4. Gaps in information
5. Confidence in findings (0-100%)
""";

            analysis = self.llm_tool.call(analysis_prompt);

            result_obj = {
                'task_id': task_id,
                'type': 'search',
                'status': 'completed',
                'search_results': search_results,
                'analysis': analysis,
                'timestamp': time.time()
            };

            self.results.append(result_obj);
            task['status'] = 'completed';

        } except Exception {
            self.handle_failure(task);
        }
    }

    def reasoning_task(task: dict) {
        task_id = task.get('task_id');
        description = task.get('description');

        try {
            prompt = f"""
Perform detailed reasoning and analysis on this task.

Task: {description}

Provide:
1. Initial analysis
2. Key considerations
3. Potential perspectives
4. Conclusions
5. Confidence level (0-100%)
""";

            analysis = self.llm_tool.call(prompt);

            result_obj = {
                'task_id': task_id,
                'type': 'reasoning',
                'status': 'completed',
                'analysis': analysis,
                'timestamp': time.time()
            };

            self.results.append(result_obj);
            task['status'] = 'completed';

        } except Exception {
            self.handle_failure(task);
        }
    }

    def handle_failure(task: dict) {
        task_id = task.get('task_id');

        if task_id not in self.retry_count {
            self.retry_count[task_id] = 0;
        }

        if self.retry_count[task_id] < self.max_retries {
            self.retry_count[task_id] += 1;
            report f"Retrying task {task_id} (attempt {self.retry_count[task_id]})";
            self.route_task(task);
        } else {
            task['status'] = 'failed';
            result_obj = {
                'task_id': task_id,
                'status': 'failed',
                'error': 'Max retries exceeded',
                'timestamp': time.time()
            };
            self.results.append(result_obj);
        }
    }
}
