"""Classify package usage from GitHub import file paths (deterministic, no LLM)."""

def _path_matches_ecosystem(path_lower: str, ecosystem: str) -> bool {
    eco = str(ecosystem).lower();
    if eco == "pypi" {
        return (
            path_lower.endswith(".py")
            or path_lower.endswith(".pyi")
        );
    }
    if eco == "go" {
        return path_lower.endswith(".go");
    }
    if eco == "maven" {
        return (
            path_lower.endswith(".java")
            or path_lower.endswith(".kt")
            or path_lower.endswith(".kts")
            or path_lower.endswith(".scala")
            or path_lower.endswith(".groovy")
        );
    }
    if eco == "auto" {
        return (
            path_lower.endswith(".ts")
            or path_lower.endswith(".js")
            or path_lower.endswith(".tsx")
            or path_lower.endswith(".jsx")
            or path_lower.endswith(".mjs")
            or path_lower.endswith(".cjs")
            or path_lower.endswith(".py")
            or path_lower.endswith(".go")
            or path_lower.endswith(".java")
            or path_lower.endswith(".kt")
        );
    }
    return (
        path_lower.endswith(".ts")
        or path_lower.endswith(".js")
        or path_lower.endswith(".tsx")
        or path_lower.endswith(".jsx")
        or path_lower.endswith(".mjs")
        or path_lower.endswith(".cjs")
    );
}

def filter_code_import_paths(
    paths: list[str],
    ecosystem: str = "npm"
) -> list[str] {
    filtered: list[str] = [];
    for path in paths {
        p = str(path);
        if _path_matches_ecosystem(p.lower(), ecosystem) {
            filtered.append(p);
        }
    }
    return filtered;
}

def classify_usage_from_paths(
    package_name: str,
    importing_files: list[str],
    ecosystem: str = "npm"
) -> dict {
    import re;

    importing_files = filter_code_import_paths(importing_files, ecosystem);

    TEST_PATTERNS = [
        r"[/\\]test[s]?[/\\]",
        r"[/\\]spec[s]?[/\\]",
        r"[/\\]__tests__[/\\]",
        r"[/\\]tests[/\\]",
        r"\.test\.[jt]sx?$",
        r"\.spec\.[jt]sx?$",
        r"test_.*\.py$",
        r"[/\\]_test\.go$",
        r"[/\\]e2e[/\\]",
        r"[/\\]cypress[/\\]",
        r"[/\\]jest[/\\]",
        r"[/\\]mocha[/\\]",
    ];

    BUILD_PATTERNS = [
        r"[/\\]scripts[/\\]",
        r"webpack\.config",
        r"rollup\.config",
        r"vite\.config",
        r"babel\.config",
        r"\.eslintrc",
        r"jest\.config",
        r"[/\\]build[/\\]",
        r"[/\\]dist[/\\]",
        r"setup\.py$",
        r"[/\\]cmd[/\\]",
    ];

    if not importing_files {
        return {
            "surface": "unknown",
            "is_prod": False,
            "importing_file_count": 0,
            "importing_files": [],
        };
    }

    test_count = 0;
    build_count = 0;
    prod_count = 0;

    for path in importing_files {
        path_lower = str(path).lower();
        is_test = False;
        is_build = False;
        for pattern in TEST_PATTERNS {
            if re.search(pattern, path_lower) {
                is_test = True;
                break;
            }
        }
        if not is_test {
            for pattern in BUILD_PATTERNS {
                if re.search(pattern, path_lower) {
                    is_build = True;
                    break;
                }
            }
        }
        if is_test {
            test_count += 1;
        } elif is_build {
            build_count += 1;
        } else {
            prod_count += 1;
        }
    }

    total = len(importing_files);

    if prod_count > 0 {
        surface = "production";
        is_prod = True;
    } elif build_count > 0 and test_count == 0 {
        surface = "build";
        is_prod = False;
    } elif test_count > 0 and prod_count == 0 {
        surface = "test";
        is_prod = False;
    } else {
        surface = "mixed";
        is_prod = prod_count > 0;
    }

    return {
        "surface": surface,
        "is_prod": is_prod,
        "importing_file_count": total,
        "importing_files": importing_files[0:6],
        "prod_count": prod_count,
        "test_count": test_count,
        "build_count": build_count,
    };
}
