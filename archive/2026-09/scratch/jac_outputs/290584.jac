""" Usage inside of generate_context:

            from plugins import plugins_filter
            for plugin in plugins_filter(plugins, "cookies"):
                context = plugin(context)

    """
def plugins_filter(plugins: list, function_name: str) -> list {
    return [x for x in plugins if x.cookiecutter_function == function_name];
}