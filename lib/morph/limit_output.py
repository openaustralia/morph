#!/usr/bin/env python3

import sys
import select
import subprocess
import argparse

# This wrapper script runs a command and lets standard out and error flow
# through. However, it does limit the number of lines of output. Morph
# uses this as a wrapper around running scrapers to ensure that they
# can't fill up the docker container log file (and hence the server disk)

def run(args, stdout_io=None, stderr_io=None):
    stdout_io = stdout_io or sys.stdout
    stderr_io = stderr_io or sys.stderr

    parser = argparse.ArgumentParser(
        usage="%(prog)s max_lines command_to_run",
        add_help=False
    )
    parser.add_argument('max_lines', type=int, nargs='?')
    parser.add_argument('command', nargs='?')

    try:
        parsed = parser.parse_args(args)
    except SystemExit:
        stderr_io.write("Usage: limit_output.py max_lines command_to_run\n")
        return 1

    if parsed.max_lines is None:
        stderr_io.write("Please give me the maximum number of lines\n")
        stderr_io.write("Usage: limit_output.py max_lines command_to_run\n")
        return 1
    if parsed.command is None:
        stderr_io.write("Please give me a command to run\n")
        stderr_io.write("Usage: limit_output.py max_lines command_to_run\n")
        return 1

    max_lines = parsed.max_lines
    command = parsed.command

    # Disable output buffering
    stdout_io.reconfigure(line_buffering=True) if hasattr(stdout_io, 'reconfigure') else None
    stderr_io.reconfigure(line_buffering=True) if hasattr(stderr_io, 'reconfigure') else None

    stdout_buffer = b""
    stderr_buffer = b""
    line_count = 0

    proc = subprocess.Popen(
        command,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    streams = {
        proc.stdout.fileno(): (proc.stdout, stdout_io, True),
        proc.stderr.fileno(): (proc.stderr, stderr_io, False)
    }

    while streams:
        readable, _, _ = select.select(list(streams.keys()), [], [])

        for fd in readable:
            pipe, output_io, is_stdout = streams[fd]

            try:
                chunk = pipe.read(1)
            except (OSError, ValueError):
                del streams[fd]
                continue

            if not chunk:
                del streams[fd]
                continue

            buffer = stdout_buffer if is_stdout else stderr_buffer
            buffer += chunk

            if chunk == b"\n":
                if line_count < max_lines or max_lines == 0:
                    output_io.buffer.write(buffer)
                    output_io.flush()
                elif line_count == max_lines:
                    stderr_io.write("limit_output.py: Too many lines of output!\n")
                    stderr_io.flush()

                if is_stdout:
                    stdout_buffer = b""
                else:
                    stderr_buffer = b""
                line_count += 1
            else:
                if is_stdout:
                    stdout_buffer = buffer
                else:
                    stderr_buffer = buffer

    # Output whatever is left in the buffers
    if line_count < max_lines or max_lines == 0:
        if stdout_buffer:
            stdout_io.buffer.write(stdout_buffer)
            stdout_io.flush()
        if stderr_buffer:
            stderr_io.buffer.write(stderr_buffer)
            stderr_io.flush()

    return_code = proc.wait()
    return return_code if return_code >= 0 else 128 + abs(return_code)

if __name__ == "__main__":
    sys.exit(run(sys.argv[1:]))
