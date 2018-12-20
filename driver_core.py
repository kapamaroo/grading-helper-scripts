#!/usr/bin/python3

import subprocess
import os
import glob
from labconf import *

NAMES = {}

def print_separator():
    print("============================================")


def exec_task_block(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, executable="/bin/bash"):
    p = subprocess.Popen(cmd, shell=True, executable=executable,
                         stdout=stdout, stderr=stderr)
    stdout, stderr = p.communicate()
    return stdout.decode('ascii'), stderr.decode('ascii'), p.returncode


active_len = 0
def init_driver_core():
    global active_len

    for key, testcase in GRADING.items():
        if key[0] == "-":
            continue

        active_len += 1

        if testcase[1]:
            NAMES[key] = testcase[1]
        GRADING[key] = testcase[0]

def Exit(error=0):
    print("{\"scores\": {", end="")
    length = active_len
    for key, testcase in GRADING.items():
        if key[0] == "-":
            continue
        length -= 1
        if key in NAMES:
            name = NAMES[key]
        else:
            name = key
        if error == 0:
            print("\"%s\": %d" %(name, GRADING[key]), end="")
        else:
            print("\"%s\": 0" %(name), end="")
        if length > 0:
            print(",", end="")
    print("}}", end="")

    exit()

def check_file(files):
    missing = False

    for f in files:
        if not os.path.isfile(f):
            print("FAILURE: missing file: %s" %(f))
            missing = True

    if missing:
        print("Submit your work again including all missing files.")
        Exit(1)


def get_files():
    l = " ".join(EXTRA_FILES)

    print("Getting files...")
    o, e, result = exec_task_block("./unpack.sh %s \".tar.gz\" %s" %(COMPRESSED, l))
    print(o, e, end="")
    GRADING["submission"] = -result
    if result == 100:
        print("Cannot extract %s" %(COMPRESSED)) # TODO print_error
        Exit(1)

def compile_(executable, flavor=""):
    grade = flavor == ""

    if flavor and not flavor.startswith("_"):
        flavor = "_" + flavor

    CFLAGS = ""
    LDFLAGS = ""

    if "LDFLAGS_%s" %(executable) in globals():
        EXTRA_LDFLAGS = globals()["LDFLAGS_%s" %(executable)]
        LDFLAGS += EXTRA_LDFLAGS

    if "CFLAGS_%s" %(executable) in globals():
        EXTRA_CFLAGS = globals()["CFLAGS_%s" %(executable)]
        CFLAGS += EXTRA_CFLAGS

    print("\nCompiling %s%s ..." %(NAME, executable))

    o, e, ret = exec_task_block("make --no-print-directory EXTRA_CFLAGS=\"%s\" EXTRA_LDFLAGS=\"%s\" FLAVOR=%s %s%s%s"
                                %(CFLAGS, LDFLAGS, flavor, NAME, executable, flavor))
    print(o, e, end='')

    if os.path.isfile("errors"):
        if grade:
            GRADING[executable + "_compilation"] = -100
        os.remove("errors")
    elif os.path.isfile("warnings"):
        if grade:
            GRADING[executable + "_compilation"] = -WARNINGS_PENALTY
        os.remove("warnings")

def clean_(executable, flavor=""):
    if flavor and not flavor.startswith("_"):
        flavor = "_" + flavor
    o, e, ret = exec_task_block("make --no-print-directory clean FLAVOR=%s" %(flavor))
    print(o, e, end='')

def run_(executable, flavor=""):
    if flavor and not flavor.startswith("_"):
        flavor = "_" + flavor
    testcases = glob.glob("%s/%s_out%s_*" %(TESTS_DIR, executable, flavor))
    num_tests = len(testcases)
    for i in range(1, num_tests + 1):
        testcase_in = executable + "_in_" + str(i)
        testcase = executable + "_out_" + str(i)
        testcase_out_flavor = executable + "_out" + flavor + "_" + str(i)
        testcase_out = testcase_out_flavor if flavor else testcase
        if not os.path.isfile(TESTS_DIR + "/" + testcase_out):
            break
        if not testcase in GRADING:
            continue
        if not os.path.isfile(NAME + executable + flavor):
            GRADING[testcase] = 0
            continue

        if os.path.isfile(TESTS_DIR + "/" + testcase_in):
            o, e, result = exec_task_block("./run.py %s%s%s --pass-stdin %s --match-stdout %s --testcase %s --grade %d"
                                           %(NAME, executable, flavor,
                                             TESTS_DIR + "/" + testcase_in,
                                             TESTS_DIR + "/" + testcase_out,
                                             testcase, GRADING[testcase]))
        else:
            o, e, result = exec_task_block("./run.py %s%s%s --match-stdout %s --testcase %s --grade %d"
                                           %(NAME, executable, flavor,
                                             TESTS_DIR + "/" + testcase_out,
                                             testcase, GRADING[testcase]))

        print(o, e)
        GRADING[testcase] = result

def __driver_core(executable):
    compile_(executable, flavor="")
    run_(executable, flavor="")
    clean_(executable, flavor="")

def driver_core():
    init_driver_core()

    get_files()
    check_file(EXTRA_FILES)

    for executable in EXEC_LIST:
        __driver_core(executable)

    print_separator()

    Exit(0)

driver_core()
