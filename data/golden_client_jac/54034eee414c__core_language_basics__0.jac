import from jac_scale.factories.sandbox_factory { SandboxFactory }

# Create sandbox using jac.toml config
glob sandbox = SandboxFactory.get_default();

# Or create with explicit type and config
glob sandbox = SandboxFactory.create("kubernetes", {
    "namespace": "jac-sandboxes",
    "base_image": "python:3.12-slim",
    "memory_limit": "1Gi",
    "ttl_seconds": 1800,
    "domain_template": "{sandbox_id}.preview.example.com"
});
