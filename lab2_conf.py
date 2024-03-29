PREFIX = "lab"
NUM = 2
NAME = PREFIX + str(NUM)

EXEC_LIST = [ "a", "b" ]

EXTRA_FILES = [ "README" ]

COMPRESSED = NAME + "submit.tar.gz"

TESTS_DIR = "tests"

MISMATCH_PENALTY = {
    "whitespace": 20,
    "case": 40,
    "other": 100
}

OUTPUT_DELIMITER = "\n#\n"

EXACT_OUTPUT = 0
TIMEOUT_LIMIT = 2

CFLAGS_a = ""
LDFLAGS_a = ""

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

# DIFF = "context_diff"
DIFF = "needle"

MAX_SIZE_FACTOR_PER_SLICE = 2

WARNINGS_PENALTY = 15

SHOW_COLOR = 0
SHOW_FIXLINE = 1
