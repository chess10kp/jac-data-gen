"""
DevOpsAudit Global Configuration
This file controls the execution mode of the entire 5-agent pipeline.
"""

# Set to "demo" to use local JSON mocks (no AWS credentials required).
# Set to "prod" to enable real boto3, OPA, CMDB, and LLM integrations.
glob env: str = "demo";
