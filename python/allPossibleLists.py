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
    arg1 = ast.literal_eval(sys.argv[1])    # Sanitize your inputs, please.
    arg2 = ast.literal_eval(sys.argv[2])
    if not isinstance(arg1, set) or not isinstance(arg2, int):
        print('One of the arguments is not of the correct type.\nEnsure you '+\
              'are using curly brackets {} for the set.')
        sys.exit(2)

n = arg2                    # n is the length of the output list
seth = list(arg1)           # `Set h' for some reason..
seth.sort()                 # Let's get them in a reasonable order
lsb = n - 1                 # LSB is the index of the last element
l = [min(seth)] * n         # Instantiate the output list with first element
turns = len(seth) ** n      # Math fun: will need to iterate the list this
cycle = 0                   #           many times
for x in range(turns):
    cur = x % len(seth)         # cur is index of inner iterations
    if cur == 0 and x != 0:     # not sure about the rest of this yet
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
