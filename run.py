#!/usr/bin/python3

import subprocess
import sys
import os
from alignment import needle
from labconf import *

def _unidiff_output(actual, expected):
    """
    Helper function. Returns a string containing the unified diff of two multiline strings.
    """

    import difflib

    expected = expected.splitlines(1)
    actual = actual.splitlines(1)

    try:
        if DIFF == "unified_diff":
            diff = difflib.unified_diff(expected, actual)
        elif DIFF == "ndiff":
            diff = difflib.ndiff(expected, actual)
        elif DIFF == "context_diff":
            diff = difflib.context_diff(expected, actual)
        else:
            diff = difflib.context_diff(expected, actual)
    except:
        diff = difflib.context_diff(expected, actual)

    out = ''.join(diff)
    return out


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


PARAMS = {}
PARAMS["STDIN"] = "--pass-stdin"
PARAMS["STDOUT"] = "--match-stdout"
PARAMS["TESTCASE"] = "--testcase"
PARAMS["GRADE"] = "--grade"

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
    delimiter = OUTPUT_DELIMITER
    Lo = output.split(delimiter)
    Go = expected_output.split(delimiter)

    if len(Lo) < len(Go):
        Lo += [ "" ] * (len(Go) - len(Lo))

    OUTPUT = "\n"
    R = 0

    for i in range(0,len(Go)):
        o, r = check_output_slice(i + 1, Lo[i], Go[i])

        OUTPUT += o
        R += r

        if r == 0:
            break

    R /= len(Go)

    if len(Lo) > len(Go):
        R *= len(Go) / len(Lo)

    return OUTPUT, R


def check_output_slice(part_num, output, expected_output):
    scaled_result = 100

    if len(output) > MAX_SIZE_FACTOR_PER_SLICE * len(expected_output):
        return "Output exceeds max size limit - Retry this step\n", 0

    if output == expected_output:
        return "%d:  Correct output\n" %(part_num), scaled_result

    scaled_result = 100 - MISMATCH_PENALTY["other"]
    OUTPUT, mismatch = __check_output(part_num, output, expected_output)
    if EXACT_OUTPUT == 1:
        return OUTPUT, scaled_result

    if mismatch["other"] > 0:
        scaled_result = 100 - MISMATCH_PENALTY["other"]
    elif mismatch["whitespace"] > 0 and mismatch["case"] > 0:
        scaled_result = 100 - (MISMATCH_PENALTY["whitespace"] + \
            MISMATCH_PENALTY["case"])
    elif mismatch["whitespace"] > 0:
        scaled_result = 100 - MISMATCH_PENALTY["whitespace"]
    elif mismatch["case"] > 0:
        scaled_result = 100 - MISMATCH_PENALTY["case"]

    return OUTPUT, scaled_result


def __check_output(part_num, output, expected_output):
    OUTPUT = ""

    mismatch = {
        "whitespace": 0,
        "case": 0,
        "other": 0
    }

    try:
        if DIFF == "needle":
            _output, _golden = needle(output, expected_output)
        else:
            OUTPUT = _unidiff_output(output, expected_output)
            mismatch["other"] = 100
            return OUTPUT, mismatch
    except:
            _output, _golden = needle(output, expected_output)

    size = len(_output)
    size2 = len(_golden)

    if size != size2:
        print("bad sizes %d %d" % (size, size2))
        exit()

    prefix = "%d:   fix :  " %(part_num)
    fix    = "%d:   fix :  " %(part_num)
    orig   = "%d:  ORIG :  " %(part_num)

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
                    OUTPUT+=orig+_orig.rstrip(os.linesep)+"\n"
                    OUTPUT+=_diff.rstrip(os.linesep)+"\n"
                    OUTPUT+=fix+_res.rstrip(os.linesep)+"\n"

            _res=""
            _orig=""
            _diff=prefix

    if SHOW_FIXLINE == 1:
        if len(_res.replace(" ","")) != 0:
            OUTPUT+=orig+_orig.rstrip(os.linesep)+"\n"
            OUTPUT+=_diff.rstrip(os.linesep)+"\n"
            OUTPUT+=fix+_res.rstrip(os.linesep)+"\n"

        _res=""
        _orig=""
        _diff=prefix

    if EXACT_OUTPUT == 0:
        mismatch["whitespace"]=whitespace
        mismatch["case"]=case_ignore
        mismatch["other"]=other

    return OUTPUT, mismatch

def print_output(scaled_result, output):
    basename = os.path.basename(EXPECTED)
    print("%s --> " %(TESTCASE), end='')
    result = int(scaled_result/100 * GRADE)

    if result != GRADE:
        print("%d/%d " %(result, GRADE), end='')
        if result != 0:
            print("-%d %%" %(100-scaled_result), end='')
    print(output, end='')
    return result


EXEC_PARAMS = ""
STDIN = ""
EXPECTED = ""
TESTCASE = ""
GRADE = 0

while (len(sys.argv[argv_idx:]) > 0):
    arg = sys.argv[argv_idx]
    shift()

    if arg in PARAMS.values():
        if len(sys.argv[argv_idx:]) == 0 or sys.argv[argv_idx] in PARAMS.values():
            print("%s provided without extra arguments")
            exit()

        if arg == PARAMS["STDIN"]:
            STDIN = OLDDIR + os.sep + sys.argv[argv_idx]
        elif arg == PARAMS["STDOUT"]:
            EXPECTED = OLDDIR + os.sep + sys.argv[argv_idx]
        elif arg == PARAMS["TESTCASE"]:
            TESTCASE = sys.argv[argv_idx]
        elif arg == PARAMS["GRADE"]:
            GRADE = int(sys.argv[argv_idx])
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

if TESTCASE == "":
    print("Missing testcase name")
    exit(100)

if GRADE <= 0 or GRADE > 100:
    print("grade out of bounds")
    exit(100)

TIMEOUT = ""
if TIMEOUT_LIMIT > 0:
    TIMEOUT = "timeout %d" % TIMEOUT_LIMIT


def print_legend():
    pass


def run():
    print_separator()
    if STDIN != "":
        output, _, timeout = exec_task_block(
            "cat %s | %s ./%s %s" % (STDIN, TIMEOUT, EXEC, EXEC_PARAMS))
    else:
        output, _, timeout = exec_task_block(
            "%s ./%s %s" % (TIMEOUT, EXEC, EXEC_PARAMS))

    result = 0
    msg = ""

    if TIMEOUT:
        if timeout == 124:
            msg = "Execution took too long (timeout = %d seconds)" % TIMEOUT_LIMIT
        elif timeout == 125:
            msg = "timeout command failure"
        elif timeout == 126:
            msg = "command %s found but cannot be executed" %(EXEC)
        elif timeout == 127:
            msg = "command %s cannot be found" %(EXEC)
        elif timeout == 137:
            msg = "%s is sent the SIGKILL signal" %(EXEC)

    if msg:
        print(msg)
    else:
        OUTPUT, scaled_result = check_output(output, expected_output)
        result = print_output(scaled_result, OUTPUT)

    return result

os.chdir(SCRDIR)
result = run()
os.chdir(OLDDIR)

exit(result)
