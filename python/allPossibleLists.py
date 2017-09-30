#!/usr/bin/python3

"""
This program prints every possible list given a length (n) and a set
"""
import ast, sys

usage = 'Usage: python3 allPossibleLists.py "<set>" <int>\n\nEx. python3 '+\
        'allPossibleLists.py "{0, 1, 2, 3}" 3'

if len(sys.argv[1:]) != 2:
    print(usage)
    sys.exit(1)
else:
    arg1 = ast.literal_eval(sys.argv[1])
    arg2 = ast.literal_eval(sys.argv[2])
    if not isinstance(arg1, set) or not isinstance(arg2, int):
        print('One of the arguments is not of the correct type.\nEnsure you '+\
              'are using curly brackets {} for the set.')
        sys.exit(2)

n = arg2
seth = list(arg1)
seth.sort()
lsb = n - 1
l = [min(seth)] * n
turns = len(seth) ** n
cycle = 0
for x in range(turns):
    cur = x % len(seth)
    if cur == 0 and x != 0:
        cycle += 1
        if cycle % len(seth) == 0:
            if n == 3:
                l[0] = seth[seth.index(l[0]) + 1]
                l[1] = seth[cur]
                l[2] = seth[cur]
                print(l)
            for y in range(n - 2, 1, -1):
                if cycle % (len(seth) ** y) == 0:
                    l[(n - 2) - y] = seth[seth.index(l[(n - 2) - y]) + 1]
                    for z in range(((n - 2) - y) + 1, n):
                        l[z] = seth[cur]
                    print(l)
                    break
                if y == 2:
                    l[lsb - 2] = seth[seth.index(l[lsb - 2]) + 1]
                    l[lsb - 1] = l[lsb] = seth[cur]
                    print(l)
        else:
            l[lsb - 1] = seth[seth.index(l[lsb - 1]) + 1]
            l[lsb] = seth[cur]
            print(l)
    else:
        l[lsb] = seth[cur]
        print(l)
