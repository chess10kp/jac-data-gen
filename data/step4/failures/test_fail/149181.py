def process_prefixes(images, prefixes):
    """
    Remove any image which prefix doesn't match what was specified
    in CLI arguments. The result will include any image which
    repository name contains the requested prefix.
    Starts by flattening the list of prefixes received from
    argparse in `[['prefix1'], ['prefix2']]` format.
    """
    flatten = lambda t: [item for sublist in t for item in sublist]
    prefixes = flatten(prefixes)

    for i in reversed(range(len(images))):
        if not any(prefix in images[i]['repository'] for prefix in prefixes):
            del images[i]
    return images

assert process_prefixes(
    [
        {'repository': 'hub/a-test'},
        {'repository': 'hub/b-test'},
    ],
    [['a']]
) == [{'repository': 'hub/a-test'}]
assert process_prefixes(
    [{'repository':'repository1'}, {'repository':'repository2'}],
    [['repository3','repository4'], ['repository1','repository2']],
) == [{'repository':'repository1'}, {'repository':'repository2'}]
assert process_prefixes(
    [{'repository':'repository1'}, {'repository':'repository2'}],
    [['repository1','repository2'], ['repository3','repository4']],
) == [{'repository':'repository1'}, {'repository':'repository2'}]
assert process_prefixes(
    [{'repository': 'hello-world'}, {'repository': 'python'}], [['hello']]) == [{'repository': 'hello-world'}]
assert process_prefixes(
    [{'repository': 'hello-world'}, {'repository': 'python'}], [['unknown']]) == []
assert process_prefixes(
    [
        {
            "repository": "ubuntu",
            "tags": []
        },
        {
            "repository": "python",
            "tags": []
        }
    ],
    [['ubuntu'], ['python']]
) == [
    {
        "repository": "ubuntu",
        "tags": []
    },
    {
        "repository": "python",
        "tags": []
    }
]
assert process_prefixes(
    [{'repository': 'prefix-foo'}],
    [['prefix']]
) == [{'repository': 'prefix-foo'}]
assert process_prefixes(
    [
        {'repository': 'test/repository1', 'tag': 'tag1'},
        {'repository': 'test/repository1', 'tag': 'tag2'}
    ],
    [['test/repository1']]
) == [{'repository': 'test/repository1', 'tag': 'tag1'}, {'repository': 'test/repository1', 'tag': 'tag2'}]
assert process_prefixes(
    [
        {'repository': 'test/repository1', 'tag': 'tag1'},
        {'repository': 'test/repository2', 'tag': 'tag2'}
    ],
    [['test/repository3']]
) == []
assert process_prefixes(
    [{'repository': 'amazon/amazon-ecs-agent-sample'}, {'repository': 'amazon/amazon-ecs-sample'}],
    [['amazon', 'amazon-ecs-agent-sample', 'amazon-ecs-sample']]) == [{'repository': 'amazon/amazon-ecs-agent-sample'}, {'repository': 'amazon/amazon-ecs-sample'}]
assert process_prefixes(
    [{'repository': 'python'}, {'repository': 'python/manylinux1'}],
    [["other"]]
) == []
assert process_prefixes(
    [{'repository':'repository1'}, {'repository':'repository2'}],
    [['repository3','repository4']],
) == []
assert process_prefixes(
    [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'},
     {'repository': 'abc', 'tag': 'latest', 'digest': 'def'}],
    [['abc', 'def'], ['abc', 'defg']]
) == [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'},
      {'repository': 'abc', 'tag': 'latest', 'digest': 'def'}]
assert process_prefixes(
    [{'repository': 'library/debian', 'tag': 'latest'}],
    ['library']
) == [{'repository': 'library/debian', 'tag': 'latest'}]
assert process_prefixes(
    [
        {
           'repository': 'nginx',
        },
        {
           'repository': 'nginx',
            'tags': [
                'latest',
                '1.0.0',
            ],
        },
    ],
    ['apache'],
) == []
assert process_prefixes(
    [{'repository': 'hello-world'}], [['hello', 'world']]) == [{'repository': 'hello-world'}]
assert process_prefixes(
    [
        {
            "repository": "ubuntu",
            "tags": []
        }
    ],
    [[]]
) == []
assert process_prefixes(
    [
        {
            "repository": "ubuntu",
            "tags": []
        },
        {
            "repository": "python",
            "tags": []
        }
    ],
    [['ubuntu', 'python']]
) == [
    {
        "repository": "ubuntu",
        "tags": []
    },
    {
        "repository": "python",
        "tags": []
    }
]
assert process_prefixes(
    [{'repository': 'library/debian', 'tag': 'latest'}],
    ['library/debian']
) == [{'repository': 'library/debian', 'tag': 'latest'}]
assert process_prefixes(
    [{'repository': 'prefix1-repository1'}],
    [['prefix1']]) == [{'repository': 'prefix1-repository1'}]
assert process_prefixes(
    [
        {'repository': 'gcr.io/google-appengine/java'},
        {'repository': 'gcr.io/google-appengine/php'},
        {'repository': 'gcr.io/google-appengine/python'},
    ],
    [
        ['java'],
        ['appengine']
    ]
) == [
    {'repository': 'gcr.io/google-appengine/java'},
    {'repository': 'gcr.io/google-appengine/php'},
    {'repository': 'gcr.io/google-appengine/python'},
]
assert process_prefixes(
    [
        {'repository': 'quay.io/ansible/ansible-runner'},
        {'repository': 'quay.io/ansible/ansible-runner-service'}
    ],
    [['ansible/ansible-runner'], ['ansible/ansible-runner-service']]
) == [
    {'repository': 'quay.io/ansible/ansible-runner'},
    {'repository': 'quay.io/ansible/ansible-runner-service'}
]
assert process_prefixes(
    [{'repository':'repository1'}, {'repository':'repository2'}],
    [['repository1','repository2']],
) == [{'repository':'repository1'}, {'repository':'repository2'}]
assert process_prefixes(
    [{"repository": "ubuntu"}, {"repository": "alpine"}],
    [["ubuntu", "alpine"]],
) == [{"repository": "ubuntu"}, {"repository": "alpine"}]
assert process_prefixes(
    [
        {'repository': 'hub/a-test'},
        {'repository': 'hub/b-test'},
    ],
    [['a', 'b']]
) == [{'repository': 'hub/a-test'}, {'repository': 'hub/b-test'}]
assert process_prefixes(
    [
        {'repository': 'hub/a-test'},
        {'repository': 'hub/b-test'},
    ],
    [['a', 'b', 'c']]
) == [{'repository': 'hub/a-test'}, {'repository': 'hub/b-test'}]
assert process_prefixes(
    [{'repository': 'amazon/amazon-ecs-agent-sample'}, {'repository': 'amazon/amazon-ecs-sample'}],
    [['amazon-ecs-agent', 'amazon-ecs-sample']]) == [{'repository': 'amazon/amazon-ecs-agent-sample'}, {'repository': 'amazon/amazon-ecs-sample'}]
assert process_prefixes(
    [{'repository': 'prefix1-repository1'},
     {'repository': 'prefix2-repository1'}],
    [['prefix2']]) == [{'repository': 'prefix2-repository1'}]
assert process_prefixes(
    [
        {'repository': 'test/image-name', 'tags': []},
        {'repository': 'test/another-image-name', 'tags': []},
    ],
    [['test/another-image-name'], ['test/another-image-name']]
) == [
    {'repository': 'test/another-image-name', 'tags': []}
]
assert process_prefixes(
    [
        {'repository': 'hub/a-test'},
        {'repository': 'hub/b-test'},
    ],
    [['c']]
) == []
assert process_prefixes(
    [{"repository": "ubuntu"}, {"repository": "alpine"}],
    [["alpine", "busybox"]],
) == [{"repository": "alpine"}]
assert process_prefixes(
    [{'repository': 'prefix-foo'}],
    [['prefix', 'foo']]
) == [{'repository': 'prefix-foo'}]
assert process_prefixes(
    [{'repository': 'prefix-foo'}],
    [['foo']]
) == [{'repository': 'prefix-foo'}]
assert process_prefixes(
    [
        {
            "repository": "ubuntu",
            "tags": []
        },
        {
            "repository": "ubuntu",
            "tags": []
        }
    ],
    [[]]
) == []
assert process_prefixes(
    [],
    [[]]
) == []
assert process_prefixes(
    [
        {
            "repository": "ubuntu",
            "tags": []
        },
        {
            "repository": "python",
            "tags": []
        }
    ],
    [['python']]
) == [{
    "repository": "python",
    "tags": []
}]
assert process_prefixes(
    [
        {'repository': 'foo/bar', 'tags': ['latest']},
        {'repository': 'foo/baz', 'tags': ['latest']},
        {'repository': 'quux/corge', 'tags': ['latest']},
        {'repository': 'quux/grault', 'tags': ['latest']},
    ],
    [['quux']]
) == [
    {'repository': 'quux/corge', 'tags': ['latest']},
    {'repository': 'quux/grault', 'tags': ['latest']},
]
assert process_prefixes(
    [{"repository": "ubuntu"}, {"repository": "alpine"}],
    [["ubuntu"]],
) == [{"repository": "ubuntu"}]
assert process_prefixes(
    [
        {'repository': 'test/image-name', 'tags': []},
        {'repository': 'test/another-image-name', 'tags': []},
        {'repository': 'test/another-image-name/something-extra', 'tags': []},
    ],
    [['test/another-image-name']]
) == [
    {'repository': 'test/another-image-name', 'tags': []},
    {'repository': 'test/another-image-name/something-extra', 'tags': []},
]
assert process_prefixes(
    [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'},
     {'repository': 'abc', 'tag': 'latest', 'digest': 'def'}],
    [['abc', 'defg']]
) == [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'},
      {'repository': 'abc', 'tag': 'latest', 'digest': 'def'}]
assert process_prefixes(
    [{'repository': 'prefix1-repository1'},
     {'repository': 'prefix1-repository2'},
     {'repository': 'prefix2-repository1'}],
    [['prefix1'], ['prefix2']]) == [{'repository': 'prefix1-repository1'},
                                   {'repository': 'prefix1-repository2'},
                                   {'repository': 'prefix2-repository1'}]
assert process_prefixes(
    [{'repository': 'python'}, {'repository': 'python/manylinux1'}],
    [["manylinux"]]
) == [{'repository': 'python/manylinux1'}]
assert process_prefixes(
    [{'repository': 'python'}, {'repository': 'python/manylinux1'}],
    [["python", "manylinux"]]
) == [{'repository': 'python'}, {'repository': 'python/manylinux1'}]
assert process_prefixes(
    [{"repository": "ubuntu"}, {"repository": "alpine"}],
    [["ubuntu", "alpine", "busybox"]],
) == [{"repository": "ubuntu"}, {"repository": "alpine"}]
assert process_prefixes(
    [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'}],
    [['abc', 'def']]
) == [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'}]
assert process_prefixes(
    [
        {'repository': 'test/repository1', 'tag': 'tag1'},
        {'repository': 'test/repository2', 'tag': 'tag2'}
    ],
    [['test/repository1']]
) == [{'repository': 'test/repository1', 'tag': 'tag1'}]
assert process_prefixes(
    [
        {'repository': 'gcr.io/google-appengine/java'},
        {'repository': 'gcr.io/google-appengine/php'},
        {'repository': 'gcr.io/google-appengine/python'},
    ],
    [
        ['java'],
        ['python']
    ]
) == [
    {'repository': 'gcr.io/google-appengine/java'},
    {'repository': 'gcr.io/google-appengine/python'},
]
assert process_prefixes(
    [{'repository': 'prefix-foo'}],
    [['foo', 'prefix']]
) == [{'repository': 'prefix-foo'}]
assert process_prefixes(
    [
        {'repository': 'test/image-name', 'tags': []},
        {'repository': 'test/another-image-name', 'tags': []},
    ],
    [['test/another-image-name']]
) == [
    {'repository': 'test/another-image-name', 'tags': []}
]
assert process_prefixes(
    [{'repository': 'library/debian', 'tag': 'latest'}],
    ['library/', 'debian']
) == [{'repository': 'library/debian', 'tag': 'latest'}]
assert process_prefixes(
    [
        {
           'repository': 'example.com/prefix1/foo',
            'tag': '1.0.0',
        },
        {
           'repository': 'example.com/prefix1/bar',
            'tag': '1.0.0',
        },
        {
           'repository': 'example.com/prefix2/foo',
            'tag': '1.0.0',
        },
    ],
    [['prefix1'], ['prefix2']]
) == [
    {
       'repository': 'example.com/prefix1/foo',
        'tag': '1.0.0',
    },
    {
       'repository': 'example.com/prefix1/bar',
        'tag': '1.0.0',
    },
    {
       'repository': 'example.com/prefix2/foo',
        'tag': '1.0.0',
    },
]
assert process_prefixes(
    [{'repository':'repository1'}, {'repository':'repository2'}],
    [['repository1'], ['repository2']],
) == [{'repository':'repository1'}, {'repository':'repository2'}]
assert process_prefixes(
    [{'repository': 'hello-world'}], [['hello'], ['world']]) == [{'repository': 'hello-world'}]
assert process_prefixes(
    [{'repository': 'prefix1-repository1'},
     {'repository': 'prefix2-repository1'}],
    [['prefix1'], ['prefix2']]) == [{'repository': 'prefix1-repository1'},
                                   {'repository': 'prefix2-repository1'}]
assert process_prefixes(
    [{'repository': 'library/debian', 'tag': 'latest'}],
    ['/debian', 'library']
) == [{'repository': 'library/debian', 'tag': 'latest'}]
assert process_prefixes(
    [
        {'repository': 'test/repository1', 'tag': 'tag1'},
        {'repository': 'test/repository2', 'tag': 'tag2'}
    ],
    [['test/repository2']]
) == [{'repository': 'test/repository2', 'tag': 'tag2'}]
assert process_prefixes(
    [
        {
            "repository": "ubuntu",
            "tags": []
        },
        {
            "repository": "python",
            "tags": []
        }
    ],
    [['ubuntu']]
) == [{
    "repository": "ubuntu",
    "tags": []
}]
assert process_prefixes(
    [{'repository': 'prefix1-repository1'},
     {'repository': 'prefix1-repository2'}],
    [['prefix1']]) == [{'repository': 'prefix1-repository1'},
                       {'repository': 'prefix1-repository2'}]
assert process_prefixes(
    [{"repository": "ubuntu"}, {"repository": "alpine"}],
    [["ubuntu", "busybox"]],
) == [{"repository": "ubuntu"}]
assert process_prefixes(
    [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'}],
    [['abc']]
) == [{'repository': 'abc', 'tag': 'latest', 'digest': 'def'}]
assert process_prefixes(
    [{'repository': 'prefix1-repository1'}],
    [['prefix2']]) == []
assert process_prefixes(
    [{'repository': 'prefix1-repository1'},
     {'repository': 'prefix1-repository2'},
     {'repository': 'prefix2-repository1'}],
    [['prefix1'], ['prefix3']]) == [{'repository': 'prefix1-repository1'},
                                   {'repository': 'prefix1-repository2'}]
assert process_prefixes(
    [
        {
           'repository': 'example.com/prefix1/foo',
            'tag': '1.0.0',
        },
        {
           'repository': 'example.com/prefix1/bar',
            'tag': '1.0.0',
        },
        {
           'repository': 'example.com/prefix2/foo',
            'tag': '1.0.0',
        },
    ],
    [['prefix1']]
) == [
    {
       'repository': 'example.com/prefix1/foo',
        'tag': '1.0.0',
    },
    {
       'repository': 'example.com/prefix1/bar',
        'tag': '1.0.0',
    },
]
assert process_prefixes(
    [
        {'repository': 'test/repository1', 'tag': 'tag1'},
        {'repository': 'test/repository2', 'tag': 'tag2'}
    ],
    [['test/repository1'], ['test/repository2']]
) == [{'repository': 'test/repository1', 'tag': 'tag1'}, {'repository': 'test/repository2', 'tag': 'tag2'}]
