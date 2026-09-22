"""Produce the default configuration section for app.config,
       when called by `resilient-circuits config [-c|-u]`
    """
def config_section_data -> str {
    config_data = """[fn_ip_void]
ipvoid_base_url=https://endpoint.apivoid.com
ipvoid_api_key=<your-api-key>
""";
    return config_data;
}