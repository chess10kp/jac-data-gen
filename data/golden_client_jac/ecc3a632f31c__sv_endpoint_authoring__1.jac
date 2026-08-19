"""Test client for Jac API servers without opening OS ports.

This module provides a test client similar to Flask's test_client(),
FastAPI's TestClient, and Django's Client. It allows testing server
endpoints without actual network I/O.

Example:
