
/*   W     W   AAA   RRRR   N   N  III  N   N   GGG   !!!
**   W     W  A   A  R   R  NN  N   I   NN  N  G   G  !!!
**   W  W  W  AAAAA  RRRR   N N N   I   N N N  G       !
**    W W W   A   A  R   R  N  NN   I   N  NN  G  GG
**     W W    A   A  R   R  N   N  III  N   N   GGG   !!!
**
** WARNING: This file is program generated by genapi.py.
**
** DO NOT EDIT THIS FILE! Any changes made to this file will be lost!
*/

#ifndef _libteacup
#define _libteacup



#ifdef __cplusplus
extern "C" {
#endif

/* Header file for libteacup */

#if !defined(_libteacup_MODULE)

/*
Extensions constructed from seperate compilation units can access the
C-API defined here by defining "libteacup_UNIQUE_SYMBOL" to a global
name unique to the extension.  Doing this circumvents the requirement
to import libteacup into each compilation unit, but is nevertheless
mildly discouraged as "outside the Python norm" and potentially
leading to problems.  Looking around at "existing Python art", most
extension modules are monolithic C files, and likely for good reason.
*/

#if defined(libteacup_UNIQUE_SYMBOL)
#define libteacup_API libteacup_UNIQUE_SYMBOL
#endif

/* C API address pointer */ 
#if defined(NO_IMPORT) || defined(NO_IMPORT_ARRAY)
extern void **libteacup_API;
#else
#if defined(libteacup_UNIQUE_SYMBOL)
void **libteacup_API;
#else
static void **libteacup_API;
#endif
#endif

#define _import_libteacup()                                                  \
      {                                                                     \
        PyObject *module = PyImport_ImportModule("numarray.libteacup");     \
        if (module != NULL) {                                               \
          PyObject *module_dict = PyModule_GetDict(module);                 \
          PyObject *c_api_object =                                          \
                 PyDict_GetItemString(module_dict, "_C_API");               \
          if (c_api_object && PyCObject_Check(c_api_object)) {              \
            libteacup_API = (void **)PyCObject_AsVoidPtr(c_api_object);      \
          } else {                                                          \
            PyErr_Format(PyExc_ImportError,                                 \
                         "Can't get API for module 'numarray.libteacup'");  \
          }                                                                 \
        }                                                                   \
      }
      
#define import_libteacup() _import_libteacup(); if (PyErr_Occurred()) { PyErr_Print(); Py_FatalError("numarray.libteacup failed to import... exiting.\n"); }
      
#endif


#define libteacup_FatalApiError (Py_FatalError("Call to API function without first calling import_libteacup() in " __FILE__), NULL)
      

/* Macros defining components of function prototypes */



#ifdef _libteacup_MODULE
  /* This section is used when compiling libteacup */

static PyObject *_Error;
  

static void *  _teacup_start_clock  (char *file, char *tag, void *cache);

static void *  _teacup_stop_clock  (char *file, char *tag, void *cache);

static PyTeaCupObject *  _teacup_get  (char *file, char *tag);

  
#else
  /* This section is used in modules that use libteacup */

#define  _teacup_start_clock (libteacup_API ? (*(void * (*)  (char *file, char *tag, void *cache) ) libteacup_API[ 0 ]) : (*(void * (*)  (char *file, char *tag, void *cache) ) libteacup_FatalApiError))

#define  _teacup_stop_clock (libteacup_API ? (*(void * (*)  (char *file, char *tag, void *cache) ) libteacup_API[ 1 ]) : (*(void * (*)  (char *file, char *tag, void *cache) ) libteacup_FatalApiError))

#define  _teacup_get (libteacup_API ? (*(PyTeaCupObject * (*)  (char *file, char *tag) ) libteacup_API[ 2 ]) : (*(PyTeaCupObject * (*)  (char *file, char *tag) ) libteacup_FatalApiError))

#endif

  /* Total number of C API pointers */
#define libteacup_API_pointers 3

#ifdef __cplusplus
}
#endif

#endif /* !defined(_libteacup) */

