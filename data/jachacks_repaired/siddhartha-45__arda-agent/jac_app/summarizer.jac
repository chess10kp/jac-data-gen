"""
Summarizer Agent - Generates final reports and recommendations
"""

import json;
import time;
import from tools.llm_tool { LLMTool }

walker GenerateReport {
    """
    Synthesizes all findings into a professional final report
    """
    has query: str;
    has tasks: list;
    has results: list;
    has reflection: dict;
    has final_report: str = "";
    has llm_tool: any = None;

    def init {
        self.llm_tool = LLMTool();
    }

    can with Root entry {
        self.synthesize_findings();
    }

    def synthesize_findings {
        synthesis_prompt = f"""
Create a comprehensive research synthesis report.

Original Query: {self.query}

Task Summary: {len(self.tasks)} tasks executed
Results: {json.dumps(self.results, indent=2, `default=str)}
Reflection: {json.dumps(self.reflection, indent=2)}

Generate a synthesis that:
1. Summarizes key findings
2. Identifies patterns and insights
3. Highlights confidence levels
4. Notes any contradictions
5. Provides evidence quality assessment

Be thorough and analytical.
""";

        synthesis = self.llm_tool.call(synthesis_prompt);
        self.final_report = synthesis;
        self.generate_recommendation();
    }

    def generate_recommendation {
        recommendation_prompt = f"""
Based on this research, provide a final recommendation/conclusion.

Query: {self.query}
Synthesis: {self.final_report}

Provide:
1. Clear recommendation
2. Supporting evidence
3. Risk assessment (if applicable)
4. Confidence level (0-100%)
5. Important caveats
""";

        recommendation = self.llm_tool.call(recommendation_prompt);
        self.format_report(recommendation);
    }

    def format_report(recommendation: str) -> dict {
        detailed_results = [];
        for result in self.results {
            detailed_results.append({
                'task_id': result.get('task_id'),
                'type': result.get('type'),
                'status': result.get('status'),
                'summary': result.get('analysis', 'N/A')[:200] + '...' if result.get('analysis') else 'N/A'
            });
        }

        formatted_report = {
            'query': self.query,
            'total_tasks': len(self.tasks),
            'completed_tasks': len([r for r in self.results if r.get('status') == 'completed']),
            'research_quality': self.reflection.get('overall_status'),
            'average_confidence': round(self.reflection.get('average_confidence', 0) * 100),
            'task_results': detailed_results,
            'synthesis': self.final_report,
            'recommendation': recommendation,
            'generated_at': time.time()
        };

        return formatted_report;
    }

    def include_reasoning_chain -> dict {
        reasoning_chain = {
            'planning_phase': [
                {'task_id': t.get('task_id'), 'description': t.get('description')}
                for t in self.tasks
            ],
            'execution_phase': [
                {'task_id': r.get('task_id'), 'status': r.get('status')}
                for r in self.results
            ],
            'reflection_phase': self.reflection,
            'decisions_made': [
                'Query analyzed and decomposed',
                'Appropriate tools selected',
                'Tasks executed with retries',
                'Results evaluated for completeness',
                'Final synthesis generated'
            ]
        };

        return reasoning_chain;
    }
}
