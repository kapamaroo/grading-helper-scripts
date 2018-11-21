#!/usr/bin/python3.6

import subprocess
import sys
import os
import re

# CONF
MISMATCH_PENALTY = {
    "whitespace": 20,
    "case": 40,
    "other": 100
}

mismatch={
    "whitespace":0,
    "case":0,
    "other":0
}

EXACT_OUTPUT = 0

GRADING = {
    "submission": (0, None),

    "a_compilation": (0, None),
    "a_out_1": (25, "a_output_1"),
    "a_out_2": (24, None),
    "a_out_3": (26, None),

    "b_compilation": (0, None),
    "b_out_1": (25, "b_output"),
    "b_out_2": (25, None)
}

SHOW_FIXLINE=1
TIMEOUT_LIMIT = 2

ALIGN_TOOLS_PATH=os.path.dirname(sys.argv[0])
ALIGN_TOOL="%s/bin/needleman_wunsch" % ALIGN_TOOLS_PATH

def _unidiff_output(expected, actual):
    """
    Helper function. Returns a string containing the unified diff of two multiline strings.
    """

    import difflib
    expected = expected.splitlines(1)
    actual = actual.splitlines(1)

    diff = difflib.unified_diff(expected, actual)

    return ''.join(diff)


def print_separator():
    print("============================================")


argv_idx = 1
def shift():
    global argv_idx
    argv_idx += 1


def exec_task_block(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, executable="/bin/bash"):
    p = subprocess.Popen(cmd, shell=True, executable=executable,
                         stdout=stdout, stderr=stderr)
    stdout, stderr = p.communicate()
    return stdout.decode('ascii'), stderr.decode('ascii'), p.returncode


PARAM_STDIN = "--pass-stdin"
PARAM_STDOUT = "--match-stdout"
SCRDIR = os.path.dirname(os.path.realpath(__file__))
OLDDIR = SCRDIR

if len(sys.argv) > 1:
    if not os.path.isfile(sys.argv[argv_idx]):
        shift()

EXEC = sys.argv[argv_idx]

shift()

if (os.path.isfile(EXEC) and not os.access(EXEC, os.X_OK)):
    print("'%s' not executable" % EXEC)
    exit(100)


def check_output(output, expected_output):
    scaled_result = 100

    if output == expected_output:
        return "Correct output\n", scaled_result

    scaled_result = 100 - MISMATCH_PENALTY["other"]
    OUTPUT = __check_output(output, expected_output)
    if EXACT_OUTPUT == 1:
        return OUTPUT, scaled_result

    if mismatch["other"] > 0:
        scaled_result = MISMATCH_PENALTY["other"]
    elif mismatch["whitespace"] > 0 and mismatch["case"] > 0:
        scaled_result = MISMATCH_PENALTY["whitespace"] + \
            MISMATCH_PENALTY["case"]
    elif mismatch["whitespace"] > 0:
        scaled_result = MISMATCH_PENALTY["whitespace"]
    elif mismatch["case"] > 0:
        scaled_result = MISMATCH_PENALTY["case"]

    scaled_result = 100 - scaled_result
    return OUTPUT, scaled_result


def __check_output(output, expected_output):
    OUTPUT = "\n"

    stdout, stderr, rc = exec_task_block(
        "%s \"~%s~\" \"~%s~\"" % (ALIGN_TOOL, output, expected_output))

    groups = [ x for x in stdout.split("~")]

    _output = groups[1]
    _golden = groups[3]

    size = len(_output)
    size2 = len(_golden)

    if size != size2:
        print("bad sizes %d %d" % (size, size2))
        exit()

    prefix="     fix :  "
    fix="     fix :  "
    orig="    ORIG :  "

    if EXACT_OUTPUT == 0:
        case_ignore=0
        whitespace=0
        other=0

    _res=""
    _orig=""
    _diff=prefix


    for i in range(0, size):
        _o=_output[i]
        _g=_golden[i]

        if _o == _g:
            _diff+=_o
            _orig+=_g
            if _g != "\n":
                _res+=" "
        elif _o == "-":
            _diff+=_g #TODO print_missing
            _orig+=_g
            _res+="+"
        elif _g == "-":
            _diff+=_o #TODO print extra
            # _orig+=_g
            _res+="-"
        else:
            _diff+=_o #TODO print_mismatch
            _orig+=_g
            _res+="?"

        if EXACT_OUTPUT == 0 and _g != _o:
            if _g.isspace():
                whitespace += 1
            elif _g.isalpha() and _g.lower() == _o.lower():
                case_ignore+=1
            else:
                other+=1
        if _g == "\n":
            if SHOW_FIXLINE == 1:
                if len(_res.replace(" ","")) != 0:
                    OUTPUT+=orig+_orig
                    OUTPUT+=_diff
                    OUTPUT+=fix+_res+"\n"

            _res=""
            _orig=""
            _diff=prefix

    if SHOW_FIXLINE == 1:
        if len(_res.replace(" ","")) != 0:
            OUTPUT+=orig+_orig
            OUTPUT+=_diff
            OUTPUT+=fix+_res+"\n"

        _res=""
        _orig=""
        _diff=prefix

    if EXACT_OUTPUT == 0:
        mismatch["whitespace"]=whitespace
        mismatch["case"]=case_ignore
        mismatch["other"]=other

    return OUTPUT

def print_output(scaled_result, output):
    basename = os.path.basename(EXPECTED)
    testcase = GRADING[basename]
    maximum = testcase[0]
    if testcase[1] is not None:
        sys.stdout.write("%s --> " % testcase[1])
    else:
        sys.stdout.write("%s --> " % basename)

    result = int(scaled_result/100 * maximum)

    if result != maximum:
        sys.stdout.write("%d/%d " % (result, maximum))
        if result != 0:
            sys.stdout.write("-%d %%" % (100-scaled_result))
    sys.stdout.write(output)
    return result


EXEC_PARAMS = ""
STDIN = ""
EXPECTED = ""

while (len(sys.argv[argv_idx:]) > 0):
    arg = sys.argv[argv_idx]
    shift()

    if arg == PARAM_STDIN or arg == PARAM_STDOUT:
        if len(sys.argv[argv_idx:]) == 0 or sys.argv[argv_idx] == PARAM_STDOUT or sys.argv[argv_idx] == PARAM_STDIN:
            print("%s provided without extra arguments")
            exit()

        if arg == PARAM_STDIN:
            STDIN = OLDDIR + os.sep + sys.argv[argv_idx]
        else:
            EXPECTED = OLDDIR + os.sep + sys.argv[argv_idx]
        shift()

    elif STDIN == "" and EXPECTED == "":
        EXEC_PARAMS = EXEC_PARAMS + " " + arg
    else:
        print ("put '%s' before any %s and %s" % (
            arg, PARAM_STDIN, PARAM_STDOUT))
        exit()

if STDIN != "" and not os.path.isfile(STDIN):
    print("Missing input file %s", STDIN)
    exit(100)

if EXPECTED != "":
    if not os.path.isfile(EXPECTED):
        print("Missing output file %s", EXPECTED)
        exit(100)

    expected_output = open(EXPECTED, "r").read()

TIMEOUT = ""
if TIMEOUT_LIMIT > 0:
    TIMEOUT = "timeout %d" % TIMEOUT_LIMIT


def print_legend():
    pass


def run():
    result = 0

    print_separator()
    if STDIN != "":
        output, _, timeout = exec_task_block(
            "cat %s | %s ./%s %s" % (STDIN, TIMEOUT, EXEC, EXEC_PARAMS))
    else:
        output, _, timeout = exec_task_block(
            "%s ./%s %s" % (TIMEOUT, EXEC, EXEC_PARAMS))

    if (timeout == 0):
        OUTPUT, scaled_result = check_output(output, expected_output)
        result = print_output(scaled_result, OUTPUT)

    else:
        print("Execution took too long (timeout = %d seconds)" % TIMEOUT_LIMIT)

    return result

os.chdir(SCRDIR)
result = run()
os.chdir(OLDDIR)

exit(result)
