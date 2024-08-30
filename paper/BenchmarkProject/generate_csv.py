#!/usr/bin/python3

"""Utility script to generate CSV data for a plot"""

import sys
import csv
import subprocess
import re
from argparse import ArgumentParser, FileType, REMAINDER
from collections import deque
from tempfile import TemporaryDirectory


ARGS = ArgumentParser(description=__doc__)
ARGS.add_argument(
    "start",
    type=int,
    help="Initial number of targets"
)
ARGS.add_argument(
    "stop",
    type=int,
    help="Final number of targets"
)
ARGS.add_argument(
    "-s",
    "--step",
    type=int,
    default=1,
    help="Target step size"
)
ARGS.add_argument(
    "-o",
    "--output",
    type=FileType("w", encoding="utf8"),
    default=sys.stdout,
    help="Output file"
)
ARGS.add_argument(
    "-j",
    "--jobs",
    type=int,
    default=1,
    help="Number of parallel CMake processes"
)
ARGS.add_argument(
    "cmake",
    nargs=REMAINDER,
    help="CMake arguments"
)

OUTPUT_REGEX = re.compile(rb"Runtime in microseconds: ([\d.]+)")

ERROR_REGEX = re.compile(rb"CMake Error at ")


def process_pending_job(targets: int, process: subprocess.Popen, directory: TemporaryDirectory) -> tuple[str, str]:
    try:
        _, stderr = process.communicate()
    except BaseException:
        process.kill()
        raise
    finally:
        directory.cleanup()
    match = OUTPUT_REGEX.search(stderr)
    # output is also contained in a CMake error, hence > 1
    if match is None or sum(1 for _ in ERROR_REGEX.finditer(stderr)) > 1:
        raise RuntimeError(f"invalid CMake output: {stderr}")
    return (str(targets), str(float(match.group(1).decode("utf8")) * 1e-6))


if __name__ == "__main__":
    args = ARGS.parse_args()
    writer = csv.writer(args.output)
    writer.writerow(("targets", "runtime"))
    pending_jobs: deque[tuple[int, subprocess.Popen, TemporaryDirectory]] = deque()
    try:
        for targets in range(args.start, args.stop, args.step):
            while not len(pending_jobs) < args.jobs:
                writer.writerow(process_pending_job(*pending_jobs.pop()))
            directory = TemporaryDirectory()
            command = ("cmake", "-S", ".", "-B", directory.name, *args.cmake, f"-DBENCHMARK_LOCALSETS={targets}")
            print(f"Executing command '{' '.join(command)}'")
            process = subprocess.Popen(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE
            )
            pending_jobs.appendleft((targets, process, directory))
    except BaseException:
        while len(pending_jobs) > 0:
            _, process, directory = pending_jobs.pop()
            process.kill()
            directory.cleanup()
        raise
    else:
        while len(pending_jobs) > 0:
            writer.writerow(process_pending_job(*pending_jobs.pop()))
