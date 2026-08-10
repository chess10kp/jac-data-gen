"""This function filters the test cases from list of test cases and returns
the test cases list."""
def get_scenario_name(cases: dict[str, list[dict[str, str]]]) -> tuple[dict[str, list[str]], dict[str, list[dict[str, str]]]] {
    test_cases_dict = {};
    test_cases_dict_json = {};
    for (class_name, test_case_list) in cases.items() {
        result = {class_name: []};
        for case_name_dict in test_case_list {
            (key, value) = list(case_name_dict.items())[0];
            class_names_dict = dict(
                (c_name, "") for scenario in result[class_name]
                for c_name in scenario.keys()
            );
            if key not in class_names_dict {
                result[class_name].append(case_name_dict);
            }
        }
        test_cases_dict_json.update(result);
        test_cases_list = list(
            dict((`case, "") for test_case in test_case_list for `case in test_case)
        );
        test_cases_dict.update({class_name: test_cases_list});
    }
    return (test_cases_dict, test_cases_dict_json);
}