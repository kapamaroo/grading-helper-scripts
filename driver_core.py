#!/usr/bin/python3

import subprocess
import os
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
    o, _, result = exec_task_block("./unpack.sh %s \".tar.gz\" %s" %(COMPRESSED, l))
    print(o, end="")
    GRADING["submission"] = -result
    if result == 100:
        print("Cannot extract %s" %(COMPRESSED)) # TODO print_error
        Exit(1)


def __driver_core(executable):
    print("\nCompiling %s%s ..." %(NAME, executable))

    exec_task_block("make --no-print-directory %s%s" %(NAME, executable))

    if os.path.isfile("errors"):
        GRADING[executable + "_compilation"] = -100
        os.remove("errors")
    elif os.path.isfile("warnings"):
        GRADING[executable + "_compilation"] = -WARNINGS_PENALTY
        os.remove("warnings")

    o, e, ret = exec_task_block("ls %s/%s_out_* |wc -l" %(TESTS_DIR, executable))
    num_tests = int(o)
    for i in range(1, num_tests + 1):
        testcase_in = executable + "_in_" + str(i)
        testcase_out = executable + "_out_" + str(i)
        if not os.path.isfile(TESTS_DIR + "/" + testcase_out):
            break
        if not testcase_out in GRADING:
            continue
        if not os.path.isfile(NAME + executable):
            GRADING[testcase_out] = 0
            continue

        if os.path.isfile(TESTS_DIR + "/" + testcase_in):
            o, e, result = exec_task_block("./run.py %s%s --pass-stdin %s --match-stdout %s"
                                           %(NAME, executable,
                                             TESTS_DIR + "/" + testcase_in,
                                             TESTS_DIR + "/" + testcase_out))
        else:
            o, e, result = exec_task_block("./run.py %s%s --match-stdout %s"
                                           %(NAME, executable,
                                             TESTS_DIR + "/" + testcase_out))

        print(o)
        GRADING[testcase_out] = result
    exec_task_block("make --no-print-directory clean")

def driver_core():
    init_driver_core()

    get_files()
    check_file(EXTRA_FILES)

    for executable in EXEC_LIST:
        __driver_core(executable)

    print_separator()

    Exit(0)

driver_core()
