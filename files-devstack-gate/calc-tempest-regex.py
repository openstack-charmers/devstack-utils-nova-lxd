#!/usr/bin/env python3

# using the file $HOME/workspace/testing/test-run.logl.txt find the errors and
# convert them to a regex that can be used to ONLY run those errors.
# Print out the resultant "tempest-dsvm-lxd-rc" file.
# This will then need to be copied to a new devstack-gate instance and
# committed to the HEAD of the nova-lxd repository so that when the gate job is
# run only the few tests that are failing are run.

import os
import textwrap


test_log_file = os.path.join(os.environ.get('HOME'), 'workspace', 'testing',
                             'test-run.log.txt')
out_file=os.path.join(os.environ.get('HOME'), 'tempest-dsvm-lxd-rc')

file_template=textwrap.dedent(
    """
    # regex to only include the failed tests
    export DEVSTACK_GATE_TEMPEST_REGEX="{regex}"
    """)


def read_failed(filename):
    """Read the filename file and look for errors at the end of each line
    return a list of lines with the failures.
    """
    with open(test_log_file) as f:
        return [s.strip() for s in f.readlines()
                if s.endswith("FAILED\n")]


def find_test_cases(failures):
    """Using the failures list, compute the test classes
    """
    return [find_test_case(s) for s in failures]


def find_test_case(failure):
    """Workout what the test case (or class is from the line.

    The format of the line is either:

    {n} some.test.Class.unit_test [time] ... FAILED

    or

    {n} some_class_method (some.test.Class) [time] ... FAILED

    Returns the some.test.Class or some.test.Class.unit_test as a string
    """
    tokens = failure.split(' ')
    if len(tokens) < 5:
        return ""
    if tokens[2].startswith("(") and tokens[2].endswith(")"):
        # we have the class based version
        return tokens[2][1:-1].split('.')
    return tokens[1].split('.')


def ensure_sane_set(test_cases):
    """Ensure that there are no 'unit_tests' if there is already a bare
    Class in the list.  This is in case a tearDown method was the issue and
    thus the whole class needs testing to see if the failure is still there.

    filter out any blank lines

    returns a sane list of test_cases
    """
    test_cases_copy = test_cases[:]
    while True:
        for i, outer_tokens in enumerate(test_cases_copy):
            restart = False
            for j, inner_tokens in enumerate(test_cases_copy):
                if i == j:
                    continue
                if (len(outer_tokens) == len(inner_tokens) - 1 and
                        outer_tokens == inner_tokens[:-1]):
                    del test_cases_copy[j]
                    restart = True
                    break
            if restart:
                break
        else:
            return test_cases_copy


def create_regex(test_cases):
    """Return the regex from the test_cases provided"""
    return "^(?:.*{}).*$".format("|".join(
        '(?:{}\[)'.format('\.'.join(s)) for s in test_cases))


def write_file(filename, regex_str):
    """write the file with the regex"""
    with open(filename, "w+") as f:
        f.write(file_template.format(regex=regex_str))


def main():
    failed_lines = read_failed(test_log_file)
    print(failed_lines)
    test_cases = find_test_cases(failed_lines)
    print(test_cases)
    sane_test_cases = ensure_sane_set(test_cases)
    print(sane_test_cases)
    regex_str = create_regex(sane_test_cases)
    print(regex_str)
    write_file(out_file, regex_str)


if __name__ == '__main__':
    main()
