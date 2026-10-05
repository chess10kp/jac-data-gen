"""
Reflection Agent - Evaluates results and determines if more research is needed
"""

import json;
import from tools.llm_tool { LLMTool }

walker ReflectOnResults {
    """
    Evaluates task results and determines quality/completeness
    """
    has query: str;
    has tasks: list;
    has results: list;
    has reflection_data: dict = {};
    has llm_tool: any = None;
    has confidence_threshold: float = 0.7;
    has assessment: dict = {};

    def init {
        self.llm_tool = LLMTool();
    }

    can with Root entry {
        self.evaluate_results();
    }

    def evaluate_results {
        self.assessment = {
            'total_tasks': len(self.tasks),
            'completed_tasks': 0,
            'failed_tasks': 0,
            'task_assessments': []
        };

        for result in self.results {
            task_assessment = self.assess_confidence(result);
            self.assessment['task_assessments'].append(task_assessment);

            if result.get('status') == 'completed' {
                self.assessment['completed_tasks'] += 1;
            } else {
                self.assessment['failed_tasks'] += 1;
            }
        }

        self.check_completeness();
    }

    def assess_confidence(result: dict) -> dict {
        result_id = result.get('task_id');

        confidence_prompt = f"""
Evaluate the quality and confidence of this research result.

Result:
{json.dumps(result, indent=2)}

Assess:
1. Information quality (0-100)
2. Completeness (0-100)
3. Reliability (0-100)
4. Need for additional research (yes/no)
5. Recommendations for improvement

Format as JSON with keys: quality, completeness, reliability, needs_more_research, recommendations
""";

        assessment_response = self.llm_tool.call(confidence_prompt);

        try {
            assessment = json.loads(assessment_response);
        } except Exception {
            assessment = {
                'quality': 70,
                'completeness': 70,
                'reliability': 70,
                'needs_more_research': False,
                'recommendations': 'Unable to parse detailed assessment'
            };
        }

        return {
            'task_id': result_id,
            'assessment': assessment,
            'avg_confidence': (assessment.get('quality', 50) + assessment.get('completeness', 50) + assessment.get('reliability', 50)) / 3
        };
    }

    def check_completeness {
        if self.assessment['completed_tasks'] == 0 {
            self.reflection_data['overall_status'] = 'insufficient_data';
        } elif self.assessment['failed_tasks'] > 0 {
            self.reflection_data['overall_status'] = 'partial_success';
        } else {
            self.reflection_data['overall_status'] = 'complete';
        }

        avg_confidence = sum([a['avg_confidence'] for a in self.assessment['task_assessments']]) / max(1, len(self.assessment['task_assessments']));
        self.reflection_data['average_confidence'] = avg_confidence;
        self.reflection_data['needs_more_research'] = avg_confidence < self.confidence_threshold;
    }

    def generate_feedback -> dict {
        feedback_prompt = f"""
Based on this research assessment, provide feedback on research completeness.

Query: {self.query}
Assessment: {json.dumps(self.assessment, indent=2)}

Provide:
1. Research quality summary
2. Key gaps remaining
3. Recommended next steps
4. Overall readiness for final report (yes/no)

Be concise and actionable.
""";

        feedback = self.llm_tool.call(feedback_prompt);
        self.reflection_data['feedback'] = feedback;

        return self.reflection_data;
    }
}
