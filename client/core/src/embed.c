#include <Python.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

unsigned int get_license(const char * sRequestData, char *sResponseData)
{
    printf("=====> enter get_license\n");
//    setenv("PYTHONPATH","/home/alice/lib",1);

    PyObject *pName, *pModule, *pDict, *pFunc, *pPyRequestData, *pOutValue;
    const char *sResult = "unknown error";
    unsigned long uResponseCode = -1;

    Py_Initialize();
    pName = PyUnicode_FromString((char*)"libalice2");
    pModule = PyImport_Import(pName);
    pDict = PyModule_GetDict(pModule);
    pFunc = PyDict_GetItemString(pDict, (char*)"get_license");
    PyErr_Print();

    if (PyCallable_Check(pFunc))
    {
        printf("=====>          callable! \n");
        pPyRequestData = Py_BuildValue("(s)", sRequestData);
        // returns tuple (code, string_data)
        pOutValue = PyObject_CallObject(pFunc, pPyRequestData);
        printf("=====> after object call\n");
        PyErr_Print();

        printf("=====> check tuple returned\n");
        if (PyTuple_Check(pOutValue) & ((unsigned int)PyTuple_Size(pOutValue) == 2))
        {
            printf("=====>           checked\n");
            uResponseCode = (unsigned long)PyLong_AsLong(PyTuple_GetItem(pOutValue, 0));
            if (uResponseCode == 200) uResponseCode = 0;
            sResult = (const char *)PyBytes_AsString(PyTuple_GetItem(pOutValue, 1));
        }
        else
        {
            uResponseCode = -2;
            sResult = "invalid tuple";
        }

        printf("=====> code    %ld\n", uResponseCode);
        printf("=====> sResult (%ld) %s\n", strlen(sResult), sResult);
        Py_DECREF(pPyRequestData);
        Py_DECREF(pOutValue);
    }
    else
    {
        PyErr_Print();
    }

    if (!sResponseData) {
        printf("=====> try to malloc %ld bytes\n", strlen(sResult + 1));
        sResponseData = malloc(strlen(sResult + 1));
    }
    if (sResponseData) {
        strcpy(sResponseData, sResult);
    }

    // Clean up
    Py_DECREF(pModule);
    Py_DECREF(pName);
    Py_DECREF(pDict);
    Py_DECREF(pFunc);
    // Finish the Python Interpreter
    Py_FinalizeEx();

    return uResponseCode;
}
