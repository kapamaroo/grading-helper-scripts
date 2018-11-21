#!/usr/bin/python3

import subprocess

from labconf import *

def exec_task_block(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, executable="/bin/bash"):
    p = subprocess.Popen(cmd, shell=True, executable=executable,
                         stdout=stdout, stderr=stderr)
    stdout, stderr = p.communicate()
    return stdout.decode('ascii'), stderr.decode('ascii'), p.returncode

o, e, ret = exec_task_block("./driver.py")

if SHOW_COLOR == 0:
    print(o)
else:
    o, e, ret = exec_task_block("echo \"%s\" | head -n-1 | ./ansi2html.sh --body-only 2> /dev/null" %(o))
    print(o)
    o, e, ret = exec_task_block("echo \"%s\" | tail -n1" %(o))
    print(o)
