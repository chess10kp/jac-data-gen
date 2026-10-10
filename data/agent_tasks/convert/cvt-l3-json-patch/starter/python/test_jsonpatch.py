#!/usr/bin/env python
# -*- coding: utf-8 -*-

import copy
import json
import decimal
import doctest
import unittest
import jsonpatch
import jsonpointer
import sys
from types import MappingProxyType


class ApplyPatchTestCase(unittest.TestCase):

    def test_apply_patch_from_string(self):
        obj = {'foo': 'bar'}
        patch = '[{"op": "add", "path": "/baz", "value": "qux"}]'
        res = jsonpatch.apply_patch(obj, patch)
        self.assertTrue(obj is not res)
        self.assertTrue('baz' in res)
        self.assertEqual(res['baz'], 'qux')

    def test_apply_patch_to_copy(self):
        obj = {'foo': 'bar'}
        res = jsonpatch.apply_patch(obj, [{'op': 'add', 'path': '/baz', 'value': 'qux'}])
        self.assertTrue(obj is not res)

    def test_apply_patch_to_same_instance(self):
        obj = {'foo': 'bar'}
        res = jsonpatch.apply_patch(obj, [{'op': 'add', 'path': '/baz', 'value': 'qux'}],
                                    in_place=True)
        self.assertTrue(obj is res)

    def test_add_object_key(self):
        obj = {'foo': 'bar'}
        res = jsonpatch.apply_patch(obj, [{'op': 'add', 'path': '/baz', 'value': 'qux'}])
        self.assertTrue('baz' in res)
        self.assertEqual(res['baz'], 'qux')

    def test_add_array_item(self):
        obj = {'foo': ['bar', 'baz']}
        res = jsonpatch.apply_patch(obj, [{'op': 'add', 'path': '/foo/1', 'value': 'qux'}])
        self.assertEqual(res['foo'], ['bar', 'qux', 'baz'])

    def test_remove_object_key(self):
        obj = {'foo': 'bar', 'baz': 'qux'}
        res = jsonpatch.apply_patch(obj, [{'op': 'remove', 'path': '/baz'}])
        self.assertTrue('baz' not in res)

    def test_remove_array_item(self):
        obj = {'foo': ['bar', 'qux', 'baz']}
        res = jsonpatch.apply_patch(obj, [{'op': 'remove', 'path': '/foo/1'}])
        self.assertEqual(res['foo'], ['bar', 'baz'])

    def test_remove_invalid_item(self):
        obj = {'foo': ['bar', 'qux', 'baz']}
        with self.assertRaises(jsonpointer.JsonPointerException):
            jsonpatch.apply_patch(obj, [{'op': 'remove', 'path': '/foo/-'}])


    def test_replace_object_key(self):
        obj = {'foo': 'bar', 'baz': 'qux'}
        res = jsonpatch.apply_patch(obj, [{'op': 'replace', 'path': '/baz', 'value': 'boo'}])
        self.assertTrue(res['baz'], 'boo')

    def test_replace_whole_document(self):
        obj = {'foo': 'bar'}
        res = jsonpatch.apply_patch(obj, [{'op': 'replace', 'path': '', 'value': {'baz': 'qux'}}])
        self.assertTrue(res['baz'], 'qux')

    def test_add_replace_whole_document(self):
        obj = {'foo': 'bar'}
        new_obj = {'baz': 'qux'}
        res = jsonpatch.apply_patch(obj, [{'op': 'add', 'path': '', 'value': new_obj}])
        # assertTrue(res, new_obj) passed a dict as the failure message, so this
        # asserted nothing; it is the object-root counterpart of the array-root
        # test below, so it needs to actually compare.
        self.assertEqual(res, new_obj)

    def test_add_replace_whole_document_list_root(self):
        # a whole document pointer resolves to part None, which has to replace
        # the document no matter whether the root is an object or an array
        obj = ['foo', 'bar']
        new_obj = {'baz': 'qux'}
        res = jsonpatch.apply_patch(obj, [{'op': 'add', 'path': '', 'value': new_obj}])
        self.assertEqual(res, new_obj)

    def test_move_whole_document_list_root(self):
        # move and copy reuse AddOperation, so they need the same treatment
        obj = ['foo', 'bar']
        res = jsonpatch.apply_patch(obj, [{'op': 'move', 'from': '/0', 'path': ''}])
        self.assertEqual(res, 'foo')

    def test_copy_whole_document_list_root(self):
        obj = ['foo', 'bar']
        res = jsonpatch.apply_patch(obj, [{'op': 'copy', 'from': '/1', 'path': ''}])
        self.assertEqual(res, 'bar')

    def test_add_whole_document_list_root_raises_no_bare_typeerror(self):
        # a bare TypeError is not part of the documented exception hierarchy, so
        # callers cannot catch it; the sequence branch must not fall through to it
        obj = ['foo', 'bar']
        try:
            jsonpatch.apply_patch(obj, [{'op': 'add', 'path': '', 'value': 'R'}])
        except jsonpatch.JsonPatchException:
            self.fail("root add on an array root should succeed, not raise")
        except TypeError:
            self.fail("root add on an array root raised a bare TypeError")

    def test_replace_array_item(self):
        obj = {'foo': ['bar', 'qux', 'baz']}
        res = jsonpatch.apply_patch(obj, [{'op': 'replace', 'path': '/foo/1',
                                           'value': 'boo'}])
        self.assertEqual(res['foo'], ['bar', 'boo', 'baz'])

    def test_apply_does_not_modify_patch(self):
        # applying a patch must not change it, so it can be applied again
        patch_obj = [
            {'op': 'add', 'path': '/foo', 'value': 'bar'},
            {'op': 'add', 'path': '/baz', 'value': [1, 2, 3]},
            {'op': 'remove', 'path': '/baz/1'},
            {'op': 'test', 'path': '/baz', 'value': [1, 3]},
            {'op': 'replace', 'path': '/baz/0', 'value': 42},
            {'op': 'remove', 'path': '/baz/1'},
        ]
        expected_patch = copy.deepcopy(patch_obj)
        patch = jsonpatch.JsonPatch(patch_obj)
        self.assertEqual(patch.apply({}), {'foo': 'bar', 'baz': [42]})
        self.assertEqual(patch.patch, expected_patch)
        self.assertEqual(patch.apply({}), {'foo': 'bar', 'baz': [42]})

    def test_apply_in_place_does_not_modify_patch(self):
        patch_obj = [
            {'op': 'add', 'path': '/foo', 'value': {'bar': [1]}},
            {'op': 'replace', 'path': '/baz', 'value': [2]},
        ]
        expected_patch = copy.deepcopy(patch_obj)
        patch = jsonpatch.JsonPatch(patch_obj)
        doc = {'baz': None}
        patch.apply(doc, in_place=True)
        doc['foo']['bar'].append(3)
        doc['baz'].append(4)
        self.assertEqual(patch.patch, expected_patch)

    def test_replace_whole_document_does_not_share_value(self):
        for op in ('add', 'replace'):
            value = {'foo': [1]}
            res = jsonpatch.apply_patch({}, [{'op': op, 'path': '', 'value': value}])
            res['foo'].append(2)
            self.assertEqual(value, {'foo': [1]})

    def test_move_object_keyerror(self):
        obj = {'foo': {'bar': 'baz'},
               'qux': {'corge': 'grault'}}
        patch_obj = [ {'op': 'move', 'from': '/foo/non-existent', 'path': '/qux/thud'} ]
        self.assertRaises(jsonpatch.JsonPatchConflict, jsonpatch.apply_patch, obj, patch_obj)

    def test_move_object_key(self):
        obj = {'foo': {'bar': 'baz', 'waldo': 'fred'},
               'qux': {'corge': 'grault'}}
        res = jsonpatch.apply_patch(obj, [{'op': 'move', 'from': '/foo/waldo',
                                           'path': '/qux/thud'}])
        self.assertEqual(res, {'qux': {'thud': 'fred', 'corge': 'grault'},
                               'foo': {'bar': 'baz'}})

    def test_move_array_item(self):
        obj =  {'foo': ['all', 'grass', 'cows', 'eat']}
        res = jsonpatch.apply_patch(obj, [{'op': 'move', 'from': '/foo/1', 'path': '/foo/3'}])
        self.assertEqual(res, {'foo': ['all', 'cows', 'eat', 'grass']})

    def test_move_array_item_into_other_item(self):
        obj = [{"foo": []}, {"bar": []}]
        patch = [{"op": "move", "from": "/0", "path": "/0/bar/0"}]
        res = jsonpatch.apply_patch(obj, patch)
        self.assertEqual(res, [{'bar': [{"foo": []}]}])

    def test_copy_object_keyerror(self):
        obj = {'foo': {'bar': 'baz'},
               'qux': {'corge': 'grault'}}
        patch_obj = [{'op': 'copy', 'from': '/foo/non-existent', 'path': '/qux/thud'}]
        self.assertRaises(jsonpatch.JsonPatchConflict, jsonpatch.apply_patch, obj, patch_obj)

    def test_copy_object_key(self):
        obj = {'foo': {'bar': 'baz', 'waldo': 'fred'},
               'qux': {'corge': 'grault'}}
        res = jsonpatch.apply_patch(obj, [{'op': 'copy', 'from': '/foo/waldo',
                                           'path': '/qux/thud'}])
        self.assertEqual(res, {'qux': {'thud': 'fred', 'corge': 'grault'},
                               'foo': {'bar': 'baz', 'waldo': 'fred'}})

    def test_copy_array_item(self):
        obj =  {'foo': ['all', 'grass', 'cows', 'eat']}
        res = jsonpatch.apply_patch(obj, [{'op': 'copy', 'from': '/foo/1', 'path': '/foo/3'}])
        self.assertEqual(res, {'foo': ['all', 'grass', 'cows', 'grass', 'eat']})


    def test_copy_mutable(self):
        """ test if mutable objects (dicts and lists) are copied by value """
        obj = {'foo': [{'bar': 42}, {'baz': 3.14}], 'boo': []}
        # copy object somewhere
        res = jsonpatch.apply_patch(obj, [{'op': 'copy', 'from': '/foo/0', 'path': '/boo/0' }])
        self.assertEqual(res, {'foo': [{'bar': 42}, {'baz': 3.14}], 'boo': [{'bar': 42}]})
        # modify original object
        res = jsonpatch.apply_patch(res, [{'op': 'add', 'path': '/foo/0/zoo', 'value': 255}])
        # check if that didn't modify the copied object
        self.assertEqual(res['boo'], [{'bar': 42}])

    def test_copy_document_into_object(self):
        for in_place in (False, True):
            obj = {'foo': [1]}
            res = jsonpatch.apply_patch(
                obj, [{'op': 'copy', 'from': '', 'path': '/snapshot'}],
                in_place=in_place)
            self.assertEqual(res, {'foo': [1], 'snapshot': {'foo': [1]}})
            self.assertEqual(res is obj, in_place)
            res['foo'].append(2)
            self.assertEqual(res['snapshot'], {'foo': [1]})
            if not in_place:
                self.assertEqual(obj, {'foo': [1]})

    def test_copy_document_into_array(self):
        for in_place in (False, True):
            obj = [[1]]
            res = jsonpatch.apply_patch(
                obj, [{'op': 'copy', 'from': '', 'path': '/-'}],
                in_place=in_place)
            self.assertEqual(res, [[1], [[1]]])
            self.assertEqual(res is obj, in_place)
            res[0].append(2)
            self.assertEqual(res[1], [[1]])
            if not in_place:
                self.assertEqual(obj, [[1]])

    def test_copy_document_to_itself(self):
        obj = {'foo': [1]}
        res = jsonpatch.apply_patch(
            obj, [{'op': 'copy', 'from': '', 'path': ''}], in_place=True)
        self.assertEqual(res, obj)
        res['foo'].append(2)
        self.assertEqual(obj, {'foo': [1]})


    def test_test_success(self):
        obj =  {'baz': 'qux', 'foo': ['a', 2, 'c']}
        jsonpatch.apply_patch(obj, [{'op': 'test', 'path': '/baz', 'value': 'qux'},
                                    {'op': 'test', 'path': '/foo/1', 'value': 2}])

    def test_test_whole_obj(self):
        obj =  {'baz': 1}
        jsonpatch.apply_patch(obj, [{'op': 'test', 'path': '', 'value': obj}])


    def test_test_error(self):
        obj =  {'bar': 'qux'}
        self.assertRaises(jsonpatch.JsonPatchTestFailed,
                          jsonpatch.apply_patch,
                          obj, [{'op': 'test', 'path': '/bar', 'value': 'bar'}])


    def test_test_not_existing(self):
        obj =  {'bar': 'qux'}
        self.assertRaises(jsonpatch.JsonPatchTestFailed,
                          jsonpatch.apply_patch,
                          obj, [{'op': 'test', 'path': '/baz', 'value': 'bar'}])


    def test_forgetting_surrounding_list(self):
        obj =  {'bar': 'qux'}
        self.assertRaises(jsonpatch.InvalidJsonPatch,
                          jsonpatch.apply_patch,
                          obj, {'op': 'test', 'path': '/bar'})

    def test_test_noval_existing(self):
        obj =  {'bar': 'qux'}
        self.assertRaises(jsonpatch.InvalidJsonPatch,
                          jsonpatch.apply_patch,
                          obj, [{'op': 'test', 'path': '/bar'}])


    def test_test_noval_not_existing(self):
        obj =  {'bar': 'qux'}
        self.assertRaises(jsonpatch.JsonPatchTestFailed,
                          jsonpatch.apply_patch,
                          obj, [{'op': 'test', 'path': '/baz'}])


    def test_test_noval_not_existing_nested(self):
        obj =  {'bar': {'qux': 2}}
        self.assertRaises(jsonpatch.JsonPatchTestFailed,
                          jsonpatch.apply_patch,
                          obj, [{'op': 'test', 'path': '/baz/qx'}])


    def test_unrecognized_element(self):
        obj = {'foo': 'bar', 'baz': 'qux'}
        res = jsonpatch.apply_patch(obj, [{'op': 'replace', 'path': '/baz', 'value': 'boo', 'foo': 'ignore'}])
        self.assertTrue(res['baz'], 'boo')


    def test_append(self):
        obj = {'foo': [1, 2]}
        res = jsonpatch.apply_patch(obj, [
                {'op': 'add', 'path': '/foo/-', 'value': 3},
                {'op': 'add', 'path': '/foo/-', 'value': 4},
            ])
        self.assertEqual(res['foo'], [1, 2, 3, 4])

    def test_add_missing_path(self):
        obj = {'bar': 'qux'}
        self.assertRaises(jsonpatch.InvalidJsonPatch,
                          jsonpatch.apply_patch,
                          obj, [{'op': 'test', 'value': 'bar'}])

    def test_path_with_null_value(self):
        obj = {'bar': 'qux'}
        self.assertRaises(jsonpatch.InvalidJsonPatch,
                          jsonpatch.apply_patch,
                          obj, '[{"op": "add", "path": null, "value": "bar"}]')


class InvalidInputTests(unittest.TestCase):

    def test_missing_op(self):
        # an "op" member is required
        src = {"foo": "bar"}
        patch_obj = [ { "path": "/child", "value": { "grandchild": { } } } ]
        self.assertRaises(jsonpatch.JsonPatchException, jsonpatch.apply_patch, src, patch_obj)


    def test_invalid_op(self):
        # "invalid" is not a valid operation
        src = {"foo": "bar"}
        patch_obj = [ { "op": "invalid", "path": "/child", "value": { "grandchild": { } } } ]
        self.assertRaises(jsonpatch.JsonPatchException, jsonpatch.apply_patch, src, patch_obj)


class ConflictTests(unittest.TestCase):

    def test_remove_indexerror(self):
        src = {"foo": [1, 2]}
        patch_obj = [ { "op": "remove", "path": "/foo/10"} ]
        self.assertRaises(jsonpatch.JsonPatchConflict, jsonpatch.apply_patch, src, patch_obj)

    def test_remove_keyerror(self):
        src = {"foo": [1, 2]}
        patch_obj = [ { "op": "remove", "path": "/foo/b"} ]
        self.assertRaises(jsonpointer.JsonPointerException, jsonpatch.apply_patch, src, patch_obj)

    def test_remove_keyerror_dict(self):
        src = {'foo': {'bar': 'barz'}}
        patch_obj = [ { "op": "remove", "path": "/foo/non-existent"} ]
        self.assertRaises(jsonpatch.JsonPatchConflict, jsonpatch.apply_patch, src, patch_obj)

    def test_insert_oob(self):
        src = {"foo": [1, 2]}
        patch_obj = [ { "op": "add", "path": "/foo/10", "value": 1} ]
        self.assertRaises(jsonpatch.JsonPatchConflict, jsonpatch.apply_patch, src, patch_obj)

    def test_move_into_child(self):
        src = {"foo": {"bar": {"baz": 1}}}
        patch_obj = [ { "op": "move", "from": "/foo", "path": "/foo/bar" } ]
        self.assertRaises(jsonpatch.JsonPatchException, jsonpatch.apply_patch, src, patch_obj)

    def test_replace_oob(self):
        src = {"foo": [1, 2]}
        patch_obj = [ { "op": "replace", "path": "/foo/10", "value": 10} ]
        self.assertRaises(jsonpatch.JsonPatchConflict, jsonpatch.apply_patch, src, patch_obj)

    def test_replace_oob_length(self):
        src = {"foo": [0, 1]}
        patch_obj = [ { "op": "replace", "path": "/foo/2", "value": 2} ]
        self.assertRaises(jsonpatch.JsonPatchConflict, jsonpatch.apply_patch, src, patch_obj)

    def test_replace_missing(self):
        src = {"foo": 1}
        patch_obj = [ { "op": "replace", "path": "/bar", "value": 10} ]
        self.assertRaises(jsonpatch.JsonPatchConflict, jsonpatch.apply_patch, src, patch_obj)


class StringIndexingTests(unittest.TestCase):
    """ RFC 6901 pointers must not index into strings (#178) """

    def setUp(self):
        self.src = {"foo": "should-not-be-indexable"}

    def test_test(self):
        patch_obj = [ { "op": "test", "path": "/foo/0", "value": "s" } ]
        self.assertRaises(jsonpatch.JsonPatchTestFailed, jsonpatch.apply_patch, self.src, patch_obj)

    def test_test_nested(self):
        patch_obj = [ { "op": "test", "path": "/foo/0/0", "value": "s" } ]
        self.assertRaises(jsonpatch.JsonPatchTestFailed, jsonpatch.apply_patch, self.src, patch_obj)

    def test_copy(self):
        patch_obj = [ { "op": "copy", "from": "/foo/0", "path": "/bar" } ]
        self.assertRaises(jsonpointer.JsonPointerException, jsonpatch.apply_patch, self.src, patch_obj)

    def test_move(self):
        patch_obj = [ { "op": "move", "from": "/foo/0", "path": "/bar" } ]
        self.assertRaises(jsonpointer.JsonPointerException, jsonpatch.apply_patch, self.src, patch_obj)

    def test_remove(self):
        patch_obj = [ { "op": "remove", "path": "/foo/0" } ]
        self.assertRaises(jsonpointer.JsonPointerException, jsonpatch.apply_patch, self.src, patch_obj)

    def test_add(self):
        patch_obj = [ { "op": "add", "path": "/foo/0", "value": "x" } ]
        self.assertRaises(jsonpointer.JsonPointerException, jsonpatch.apply_patch, self.src, patch_obj)

    def test_replace(self):
        patch_obj = [ { "op": "replace", "path": "/foo/0", "value": "x" } ]
        self.assertRaises(jsonpointer.JsonPointerException, jsonpatch.apply_patch, self.src, patch_obj)

    def test_root_string(self):
        patch_obj = [ { "op": "test", "path": "/0", "value": "a" } ]
        self.assertRaises(jsonpatch.JsonPatchTestFailed, jsonpatch.apply_patch, "abc", patch_obj)

    def test_whole_string_value(self):
        patch_obj = [
            { "op": "test", "path": "/foo", "value": "should-not-be-indexable" },
            { "op": "copy", "from": "/foo", "path": "/bar" },
        ]
        res = jsonpatch.apply_patch(self.src, patch_obj)
        self.assertEqual(res, {"foo": "should-not-be-indexable",
                               "bar": "should-not-be-indexable"})

    def test_root_string_whole_document(self):
        patch_obj = [ { "op": "test", "path": "", "value": "abc" } ]
        self.assertEqual(jsonpatch.apply_patch("abc", patch_obj), "abc")


if __name__ == '__main__':
    modules = ['jsonpatch']


    def get_suite():
        suite = unittest.TestSuite()
        suite.addTest(doctest.DocTestSuite(jsonpatch))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(ApplyPatchTestCase))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(EqualityTestCase))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(MakePatchTestCase))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(ListTests))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(InvalidInputTests))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(ConflictTests))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(StringIndexingTests))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(OptimizationTests))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(JsonPointerTests))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(JsonPatchCreationTest))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(UtilityMethodTests))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(CustomJsonPointerTests))
        suite.addTest(unittest.defaultTestLoader.loadTestsFromTestCase(CustomOperationTests))
        return suite


    suite = get_suite()

    for module in modules:
        m = __import__(module, fromlist=[module])
        suite.addTest(doctest.DocTestSuite(m))

    runner = unittest.TextTestRunner(verbosity=1)

    result = runner.run(suite)

    if not result.wasSuccessful():
        sys.exit(1)
