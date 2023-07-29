#!/usr/bin/env python3
"""
Split a file into a set of parts
Use join.py to re-assemble the file
"""

import os, sys

KILOBYTES = 1024
MEGABYTES = 1000 * KILOBYTES
CHUNKSIZE = int(1.4 * MEGABYTES)


def split(from_file, to_dir, chunksize=CHUNKSIZE):
    if not os.path.exists(to_dir):
        os.mkdir(to_dir)
    else:
        for file_name in os.listdir(to_dir):
            os.remove(os.path.join(to_dir, file_name))
    part_number = 0
    from_file_obj = open(from_file, "rb")
    while True:
        chunk = from_file_obj.read(chunksize)
        if not chunk:
            break
        part_number += 1
        file_name = os.path.join(to_dir, ("part%04d" % part_number))
        to_file = open(file_name, "wb")
        to_file.write(chunk)
        to_file.close()
    from_file_obj.close()
    assert part_number <= 9999
    return part_number


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "-help":
        print("Use: split.py [file-to-split target-dir [chunksize]]")
    else:
        if len(sys.argv) < 3:
            interactive = True
            from_file = input("File to be split? ")
            to_dir = input("Directory to store part files? ")
        else:
            interactive = False
            from_file, to_dir = sys.argv[1:3]
            if len(sys.argv) == 4:
                chunksize = int(sys.argv[3])
        from_abs, to_abs = map(os.path.abspath, [from_file, to_dir])
        print("Splitting", from_abs, "to", to_abs, "by", chunksize)
        try:
            parts = split(from_file, to_dir, chunksize)
        except:
            print("Error during split:")
            print(sys.exc_info()[0], sys.exc_info()[1])
        else:
            print("Split finished:", parts, "parts are in", to_abs)
        if interactive:
            input("Press ENTER key")
