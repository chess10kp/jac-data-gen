/* PyCapsule binding shim for tree-sitter >= 0.25's Language(capsule) API.
 * Exposes language() -> capsule named "tree_sitter.Language" wrapping the
 * TSLanguage pointer produced by the generated parser. */
#include <Python.h>

typedef struct TSLanguage TSLanguage;

extern TSLanguage *tree_sitter_jac(void);

static PyObject *binding_language(PyObject *Py_UNUSED(self),
                                  PyObject *Py_UNUSED(args)) {
  return PyCapsule_New(tree_sitter_jac(), "tree_sitter.Language", NULL);
}

static PyMethodDef methods[] = {
    {"language", binding_language, METH_NOARGS,
     "Get the tree-sitter Language capsule for the Jac grammar."},
    {NULL, NULL, 0, NULL}};

static struct PyModuleDef module = {
    PyModuleDef_HEAD_INIT, "tree_sitter_jac.binding",
    "Local binding for the tree-sitter-jac grammar.", -1, methods,
    NULL, NULL, NULL, NULL};

PyMODINIT_FUNC PyInit_binding(void) { return PyModule_Create(&module); }
