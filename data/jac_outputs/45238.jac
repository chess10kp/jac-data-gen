"""Contains skills required for python developers."""
def get_python(spec: str | None = 'general') -> list[str] | tuple[list[str], list[str]] | None {
    skills = [
        "Flask",
        "Django",
        "Machine Learning",
        "Artificial Intelligence",
        "SQL",
        "MongoDB",
        "REST",
        "Deep Learning",
        "Selenium",
        "Tkinter"
    ];
    advanced_skills = ['Blockchain', 'AWS', 'Big Data', 'Automation', 'Microservices'];
    python_build_tools = ['BuildBot', 'PyMake'];
    web_tech = ['HTML', 'CSS', 'Javascript'];
    web_frameworks = ['Flask', 'Django'];
    app_containers = ['python-docker-client', 'python-kuebrnetes-client'];
    automation_tools = ['Selenium', 'Robot', 'Pytest'];
    machine_learning = [
        'Regression',
        'Classification',
        'Clustering',
        'ANN',
        'CNN',
        'RNN'
    ];
    code_version_control = ['GitHub'];
    name_var_dict = [
        {'pythonbuildtools': python_build_tools},
        {'webtechnologies': web_tech},
        {'webframeworks': web_frameworks},
        {'applicationcontainers': app_containers},
        {'pythonautomationtools': automation_tools},
        {'machinelearning': machine_learning},
        {'codeversioncontrol': code_version_control}
    ];
    if spec is None {
        return skills;
    }
    if spec.lower() == 'general' {
        return (skills, advanced_skills);
    }
    for key in name_var_dict {
        temp = spec.lower().strip().replace(" ", "");
        if temp in list(key.keys())[0] {
            idx = name_var_dict.index(key);
            return name_var_dict[idx][list(key.keys())[0]];
        }
    }
}