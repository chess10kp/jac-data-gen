"""
    Remove any image which prefix doesn't match what was specified
    in CLI arguments. The result will include any image which
    repository name contains the requested prefix.
    Starts by flattening the list of prefixes received from
    argparse in `[['prefix1'], ['prefix2']]` format.
    """
def process_prefixes(images: Any, prefixes: Any) -> object {
    flatten = lambda (t: Any) { [item for sublist in t for item in sublist]; };
    prefixes = flatten(prefixes);
    for i in reversed(range(len(images))) {
        if not `any((prefix in images[i]['repository']) for prefix in prefixes) {
            delete(images[i],);
        }
    }
    return images;
}

test "t0" {
    assert (
        process_prefixes(
            [{'repository': 'hub/a-test'}, {'repository': 'hub/b-test'}], [['a']]
        )
        == [{'repository': 'hub/a-test'}]
    );;
}

test "t1" {
    assert (
        process_prefixes(
            [{'repository': 'repository1'}, {'repository': 'repository2'}],
            [['repository3', 'repository4'], ['repository1', 'repository2']]
        )
        == [{'repository': 'repository1'}, {'repository': 'repository2'}]
    );;
}

test "t2" {
    assert (
        process_prefixes(
            [{'repository': 'repository1'}, {'repository': 'repository2'}],
            [['repository1', 'repository2'], ['repository3', 'repository4']]
        )
        == [{'repository': 'repository1'}, {'repository': 'repository2'}]
    );;
}

test "t3" {
    assert (
        process_prefixes(
            [{'repository': 'hello-world'}, {'repository': 'python'}], [['hello']]
        )
        == [{'repository': 'hello-world'}]
    );;
}

test "t4" {
    assert (
        process_prefixes(
            [{'repository': 'hello-world'}, {'repository': 'python'}], [['unknown']]
        )
        == []
    );;
}

test "t5" {
    assert (
        process_prefixes(
            [
                {"repository": "ubuntu", "tags": []},
                {"repository": "python", "tags": []}
            ],
            [['ubuntu'], ['python']]
        )
        == [{"repository": "ubuntu", "tags": []}, {"repository": "python", "tags": []}]
    );;
}

test "t6" {
    assert (
        process_prefixes([{'repository': 'prefix-foo'}], [['prefix']])
        == [{'repository': 'prefix-foo'}]
    );;
}

test "t7" {
    assert (
        process_prefixes(
            [
                {'repository': 'test/repository1', 'tag': 'tag1'},
                {'repository': 'test/repository1', 'tag': 'tag2'}
            ],
            [['test/repository1']]
        )
        == [
            {'repository': 'test/repository1', 'tag': 'tag1'},
            {'repository': 'test/repository1', 'tag': 'tag2'}
        ]
    );;
}

test "t8" {
    assert (
        process_prefixes(
            [
                {'repository': 'test/repository1', 'tag': 'tag1'},
                {'repository': 'test/repository2', 'tag': 'tag2'}
            ],
            [['test/repository3']]
        )
        == []
    );;
}

test "t9" {
    assert (
        process_prefixes(
            [
                {'repository': 'amazon/amazon-ecs-agent-sample'},
                {'repository': 'amazon/amazon-ecs-sample'}
            ],
            [['amazon', 'amazon-ecs-agent-sample', 'amazon-ecs-sample']]
        )
        == [
            {'repository': 'amazon/amazon-ecs-agent-sample'},
            {'repository': 'amazon/amazon-ecs-sample'}
        ]
    );;
}

test "t10" {
    assert (
        process_prefixes(
            [{'repository': 'python'}, {'repository': 'python/manylinux1'}], [["other"]]
        )
        == []
    );;
}

test "t11" {
    assert (
        process_prefixes(
            [{'repository': 'repository1'}, {'repository': 'repository2'}],
            [['repository3', 'repository4']]
        )
        == []
    );;
}

test "t12" {
    assert (
        process_prefixes(
            [
                {'repository': 'abc', 'tag': 'latest', 'digest': 'def'},
                {'repository': 'abc', 'tag': 'latest', 'digest': 'def'}
            ],
            [['abc', 'def'], ['abc', 'defg']]
        )
        == [
            {'repository': 'abc', 'tag': 'latest', 'digest': 'def'},
            {'repository': 'abc', 'tag': 'latest', 'digest': 'def'}
        ]
    );;
}

test "t13" {
    assert (
        process_prefixes(
            [{'repository': 'library/debian', 'tag': 'latest'}], ['library']
        )
        == [{'repository': 'library/debian', 'tag': 'latest'}]
    );;
}

test "t14" {
    assert (
        process_prefixes(
            [
                {'repository': 'nginx'},
                {'repository': 'nginx', 'tags': ['latest', '1.0.0']}
            ],
            ['apache']
        )
        == []
    );;
}

test "t15" {
    assert (
        process_prefixes([{'repository': 'hello-world'}], [['hello', 'world']])
        == [{'repository': 'hello-world'}]
    );;
}

test "t16" {
    assert (process_prefixes([{"repository": "ubuntu", "tags": []}], [[]]) == []);;
}

test "t17" {
    assert (
        process_prefixes(
            [
                {"repository": "ubuntu", "tags": []},
                {"repository": "python", "tags": []}
            ],
            [['ubuntu', 'python']]
        )
        == [{"repository": "ubuntu", "tags": []}, {"repository": "python", "tags": []}]
    );;
}

test "t18" {
    assert (
        process_prefixes(
            [{'repository': 'library/debian', 'tag': 'latest'}], ['library/debian']
        )
        == [{'repository': 'library/debian', 'tag': 'latest'}]
    );;
}

test "t19" {
    assert (
        process_prefixes([{'repository': 'prefix1-repository1'}], [['prefix1']])
        == [{'repository': 'prefix1-repository1'}]
    );;
}

test "t20" {
    assert (
        process_prefixes(
            [
                {'repository': 'gcr.io/google-appengine/java'},
                {'repository': 'gcr.io/google-appengine/php'},
                {'repository': 'gcr.io/google-appengine/python'}
            ],
            [['java'], ['appengine']]
        )
        == [
            {'repository': 'gcr.io/google-appengine/java'},
            {'repository': 'gcr.io/google-appengine/php'},
            {'repository': 'gcr.io/google-appengine/python'}
        ]
    );;
}

test "t21" {
    assert (
        process_prefixes(
            [
                {'repository': 'quay.io/ansible/ansible-runner'},
                {'repository': 'quay.io/ansible/ansible-runner-service'}
            ],
            [['ansible/ansible-runner'], ['ansible/ansible-runner-service']]
        )
        == [
            {'repository': 'quay.io/ansible/ansible-runner'},
            {'repository': 'quay.io/ansible/ansible-runner-service'}
        ]
    );;
}

test "t22" {
    assert (
        process_prefixes(
            [{'repository': 'repository1'}, {'repository': 'repository2'}],
            [['repository1', 'repository2']]
        )
        == [{'repository': 'repository1'}, {'repository': 'repository2'}]
    );;
}

test "t23" {
    assert (
        process_prefixes(
            [{"repository": "ubuntu"}, {"repository": "alpine"}], [["ubuntu", "alpine"]]
        )
        == [{"repository": "ubuntu"}, {"repository": "alpine"}]
    );;
}

test "t24" {
    assert (
        process_prefixes(
            [{'repository': 'hub/a-test'}, {'repository': 'hub/b-test'}], [['a', 'b']]
        )
        == [{'repository': 'hub/a-test'}, {'repository': 'hub/b-test'}]
    );;
}

test "t25" {
    assert (
        process_prefixes(
            [{'repository': 'hub/a-test'}, {'repository': 'hub/b-test'}],
            [['a', 'b', 'c']]
        )
        == [{'repository': 'hub/a-test'}, {'repository': 'hub/b-test'}]
    );;
}

test "t26" {
    assert (
        process_prefixes(
            [
                {'repository': 'amazon/amazon-ecs-agent-sample'},
                {'repository': 'amazon/amazon-ecs-sample'}
            ],
            [['amazon-ecs-agent', 'amazon-ecs-sample']]
        )
        == [
            {'repository': 'amazon/amazon-ecs-agent-sample'},
            {'repository': 'amazon/amazon-ecs-sample'}
        ]
    );;
}

test "t27" {
    assert (
        process_prefixes(
            [
                {'repository': 'prefix1-repository1'},
                {'repository': 'prefix2-repository1'}
            ],
            [['prefix2']]
        )
        == [{'repository': 'prefix2-repository1'}]
    );;
}

test "t28" {
    assert (
        process_prefixes(
            [
                {'repository': 'test/image-name', 'tags': []},
                {'repository': 'test/another-image-name', 'tags': []}
            ],
            [['test/another-image-name'], ['test/another-image-name']]
        )
        == [{'repository': 'test/another-image-name', 'tags': []}]
    );;
}

test "t29" {
    assert (
        process_prefixes(
            [{'repository': 'hub/a-test'}, {'repository': 'hub/b-test'}], [['c']]
        )
        == []
    );;
}

test "t30" {
    assert (
        process_prefixes(
            [{"repository": "ubuntu"}, {"repository": "alpine"}],
            [["alpine", "busybox"]]
        )
        == [{"repository": "alpine"}]
    );;
}

test "t31" {
    assert (
        process_prefixes([{'repository': 'prefix-foo'}], [['prefix', 'foo']])
        == [{'repository': 'prefix-foo'}]
    );;
}

test "t32" {
    assert (
        process_prefixes([{'repository': 'prefix-foo'}], [['foo']])
        == [{'repository': 'prefix-foo'}]
    );;
}

test "t33" {
    assert (
        process_prefixes(
            [
                {"repository": "ubuntu", "tags": []},
                {"repository": "ubuntu", "tags": []}
            ],
            [[]]
        )
        == []
    );;
}

test "t34" {
    assert (process_prefixes([], [[]]) == []);;
}

test "t35" {
    assert (
        process_prefixes(
            [
                {"repository": "ubuntu", "tags": []},
                {"repository": "python", "tags": []}
            ],
            [['python']]
        )
        == [{"repository": "python", "tags": []}]
    );;
}

test "t36" {
    assert (
        process_prefixes(
            [
                {'repository': 'foo/bar', 'tags': ['latest']},
                {'repository': 'foo/baz', 'tags': ['latest']},
                {'repository': 'quux/corge', 'tags': ['latest']},
                {'repository': 'quux/grault', 'tags': ['latest']}
            ],
            [['quux']]
        )
        == [
            {'repository': 'quux/corge', 'tags': ['latest']},
            {'repository': 'quux/grault', 'tags': ['latest']}
        ]
    );;
}

test "t37" {
    assert (
        process_prefixes(
            [{"repository": "ubuntu"}, {"repository": "alpine"}], [["ubuntu"]]
        )
        == [{"repository": "ubuntu"}]
    );;
}

test "t38" {
    assert (
        process_prefixes(
            [
                {'repository': 'test/image-name', 'tags': []},
                {'repository': 'test/another-image-name', 'tags': []},
                {'repository': 'test/another-image-name/something-extra', 'tags': []}
            ],
            [['test/another-image-name']]
        )
        == [
            {'repository': 'test/another-image-name', 'tags': []},
            {'repository': 'test/another-image-name/something-extra', 'tags': []}
        ]
    );;
}

test "t39" {
    assert (
        process_prefixes(
            [
                {'repository': 'abc', 'tag': 'latest', 'digest': 'def'},
                {'repository': 'abc', 'tag': 'latest', 'digest': 'def'}
            ],
            [['abc', 'defg']]
        )
        == [
            {'repository': 'abc', 'tag': 'latest', 'digest': 'def'},
            {'repository': 'abc', 'tag': 'latest', 'digest': 'def'}
        ]
    );;
}

test "t40" {
    assert (
        process_prefixes(
            [
                {'repository': 'prefix1-repository1'},
                {'repository': 'prefix1-repository2'},
                {'repository': 'prefix2-repository1'}
            ],
            [['prefix1'], ['prefix2']]
        )
        == [
            {'repository': 'prefix1-repository1'},
            {'repository': 'prefix1-repository2'},
            {'repository': 'prefix2-repository1'}
        ]
    );;
}

test "t41" {
    assert (
        process_prefixes(
            [{'repository': 'python'}, {'repository': 'python/manylinux1'}],
            [["manylinux"]]
        )
        == [{'repository': 'python/manylinux1'}]
    );;
}

test "t42" {
    assert (
        process_prefixes(
            [{'repository': 'python'}, {'repository': 'python/manylinux1'}],
            [["python", "manylinux"]]
        )
        == [{'repository': 'python'}, {'repository': 'python/manylinux1'}]
    );;
}

test "t43" {
    assert (
        process_prefixes(
            [{"repository": "ubuntu"}, {"repository": "alpine"}],
            [["ubuntu", "alpine", "busybox"]]
        )
        == [{"repository": "ubuntu"}, {"repository": "alpine"}]
    );;
}

test "t44" {
    assert (
        process_prefixes(
            [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'}], [['abc', 'def']]
        )
        == [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'}]
    );;
}

test "t45" {
    assert (
        process_prefixes(
            [
                {'repository': 'test/repository1', 'tag': 'tag1'},
                {'repository': 'test/repository2', 'tag': 'tag2'}
            ],
            [['test/repository1']]
        )
        == [{'repository': 'test/repository1', 'tag': 'tag1'}]
    );;
}

test "t46" {
    assert (
        process_prefixes(
            [
                {'repository': 'gcr.io/google-appengine/java'},
                {'repository': 'gcr.io/google-appengine/php'},
                {'repository': 'gcr.io/google-appengine/python'}
            ],
            [['java'], ['python']]
        )
        == [
            {'repository': 'gcr.io/google-appengine/java'},
            {'repository': 'gcr.io/google-appengine/python'}
        ]
    );;
}

test "t47" {
    assert (
        process_prefixes([{'repository': 'prefix-foo'}], [['foo', 'prefix']])
        == [{'repository': 'prefix-foo'}]
    );;
}

test "t48" {
    assert (
        process_prefixes(
            [
                {'repository': 'test/image-name', 'tags': []},
                {'repository': 'test/another-image-name', 'tags': []}
            ],
            [['test/another-image-name']]
        )
        == [{'repository': 'test/another-image-name', 'tags': []}]
    );;
}

test "t49" {
    assert (
        process_prefixes(
            [{'repository': 'library/debian', 'tag': 'latest'}], ['library/', 'debian']
        )
        == [{'repository': 'library/debian', 'tag': 'latest'}]
    );;
}

test "t50" {
    assert (
        process_prefixes(
            [
                {'repository': 'example.com/prefix1/foo', 'tag': '1.0.0'},
                {'repository': 'example.com/prefix1/bar', 'tag': '1.0.0'},
                {'repository': 'example.com/prefix2/foo', 'tag': '1.0.0'}
            ],
            [['prefix1'], ['prefix2']]
        )
        == [
            {'repository': 'example.com/prefix1/foo', 'tag': '1.0.0'},
            {'repository': 'example.com/prefix1/bar', 'tag': '1.0.0'},
            {'repository': 'example.com/prefix2/foo', 'tag': '1.0.0'}
        ]
    );;
}

test "t51" {
    assert (
        process_prefixes(
            [{'repository': 'repository1'}, {'repository': 'repository2'}],
            [['repository1'], ['repository2']]
        )
        == [{'repository': 'repository1'}, {'repository': 'repository2'}]
    );;
}

test "t52" {
    assert (
        process_prefixes([{'repository': 'hello-world'}], [['hello'], ['world']])
        == [{'repository': 'hello-world'}]
    );;
}

test "t53" {
    assert (
        process_prefixes(
            [
                {'repository': 'prefix1-repository1'},
                {'repository': 'prefix2-repository1'}
            ],
            [['prefix1'], ['prefix2']]
        )
        == [
            {'repository': 'prefix1-repository1'},
            {'repository': 'prefix2-repository1'}
        ]
    );;
}

test "t54" {
    assert (
        process_prefixes(
            [{'repository': 'library/debian', 'tag': 'latest'}], ['/debian', 'library']
        )
        == [{'repository': 'library/debian', 'tag': 'latest'}]
    );;
}

test "t55" {
    assert (
        process_prefixes(
            [
                {'repository': 'test/repository1', 'tag': 'tag1'},
                {'repository': 'test/repository2', 'tag': 'tag2'}
            ],
            [['test/repository2']]
        )
        == [{'repository': 'test/repository2', 'tag': 'tag2'}]
    );;
}

test "t56" {
    assert (
        process_prefixes(
            [
                {"repository": "ubuntu", "tags": []},
                {"repository": "python", "tags": []}
            ],
            [['ubuntu']]
        )
        == [{"repository": "ubuntu", "tags": []}]
    );;
}

test "t57" {
    assert (
        process_prefixes(
            [
                {'repository': 'prefix1-repository1'},
                {'repository': 'prefix1-repository2'}
            ],
            [['prefix1']]
        )
        == [
            {'repository': 'prefix1-repository1'},
            {'repository': 'prefix1-repository2'}
        ]
    );;
}

test "t58" {
    assert (
        process_prefixes(
            [{"repository": "ubuntu"}, {"repository": "alpine"}],
            [["ubuntu", "busybox"]]
        )
        == [{"repository": "ubuntu"}]
    );;
}

test "t59" {
    assert (
        process_prefixes(
            [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'}], [['abc']]
        )
        == [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'}]
    );;
}

test "t60" {
    assert (
        process_prefixes([{'repository': 'prefix1-repository1'}], [['prefix2']]) == []
    );;
}

test "t61" {
    assert (
        process_prefixes(
            [
                {'repository': 'prefix1-repository1'},
                {'repository': 'prefix1-repository2'},
                {'repository': 'prefix2-repository1'}
            ],
            [['prefix1'], ['prefix3']]
        )
        == [
            {'repository': 'prefix1-repository1'},
            {'repository': 'prefix1-repository2'}
        ]
    );;
}

test "t62" {
    assert (
        process_prefixes(
            [
                {'repository': 'example.com/prefix1/foo', 'tag': '1.0.0'},
                {'repository': 'example.com/prefix1/bar', 'tag': '1.0.0'},
                {'repository': 'example.com/prefix2/foo', 'tag': '1.0.0'}
            ],
            [['prefix1']]
        )
        == [
            {'repository': 'example.com/prefix1/foo', 'tag': '1.0.0'},
            {'repository': 'example.com/prefix1/bar', 'tag': '1.0.0'}
        ]
    );;
}

test "t63" {
    assert (
        process_prefixes(
            [
                {'repository': 'test/repository1', 'tag': 'tag1'},
                {'repository': 'test/repository2', 'tag': 'tag2'}
            ],
            [['test/repository1'], ['test/repository2']]
        )
        == [
            {'repository': 'test/repository1', 'tag': 'tag1'},
            {'repository': 'test/repository2', 'tag': 'tag2'}
        ]
    );;
}
