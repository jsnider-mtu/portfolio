#!/usr/bin/env python3
"""
Join all part files in a dir created by split.py
"""

import os, sys

READSIZE = 1024


def join(from_dir, to_file):
    output = open(to_file, "wb")
    parts = os.listdir(from_dir)
    parts.sort()
    for file_name in parts:
        file_path = os.path.join(from_dir, file_name)
        file = open(file_path, "rb")
        while True:
            file_bytes = file.read(READSIZE)
            if not file_bytes:
                break
            output.write(file_bytes)
        file.close()
    output.close()


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "-help":
        print("Use: join.py [from-dir-name to-file-name]")
    else:
        if len(sys.argv) != 3:
            interactive = True
            from_dir = input("Directory containing part files? ")
            to_file = input("Name of file to be recreated? ")
        else:
            interactive = False
            from_dir, to_file = sys.argv[1:]
        from_abs, to_abs = map(os.path.abspath, [from_dir, to_file])
        print("Joining", from_abs, "to make", to_abs)
        try:
            join(from_dir, to_file)
        except:
            print("Error joining files:")
            print(sys.exc_info()[0], sys.exc_info()[1])
        else:
            print("Join complete: see", to_abs)
        if interactive:
            input("Press ENTER key")
