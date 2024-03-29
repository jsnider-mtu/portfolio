#!/usr/bin/env python3
"""
This is a board game that uses a set of maps and a set of execution
paths as well as command tokens and modifier tokens.

I'm going to make the maps using a linked-list type data structure:
each map has a set of points, each point has a color link to another
point, or null meaning not a valid path.

map = [[redPoint, bluePoint, greenPoint, monster], [],...]

While executing, the avatar's next position will be determined by
looking up the next point in the map like so: map[startingPoint][color]
If the value returned is None then the solution is incorrect as there
is no path forward.
The monster value describes any monsters residing at that point:
0 = none, 1 = purple, 2 = orange


A level is defined by a map, a scroll, avatar position, portal position,
a number of crystals each with a position, modifier tokens, and command
tokens.

level = [map index, scroll index, avatar position, portal position, crystals,
            modifier tokens, command tokens]
modifier tokens = [1, 2, 3, 4, 5, 6, 'o', 'p']  # o and p for orange and purple
command tokens = {0: number of tokens, 1: , 2: }  # red = 0, blue = 1, green = 2

A scroll is run through in sequence, and at conditionals can move the seq pointer
back to a previous position.

A scroll pointer starts at 0 and tracks execution of the scroll.

Execution steps:
Execute command at current position of scroll pointer or check conditional
Move player to next position if command and then move the scroll pointer
Check for crystals and pick up one if can
If scroll pointer == portal, check that avatar is at portal position for win
If so then check crystal count for win

Solutions:
rgrg
brbr
bgbr
brgbr
gbrb
rbgbr
rgrgb
grbr
rgrbg
rbrgrb
grrb
rgbrg
rrrgb
gbgrb
bgrbr
rbg6
gbgrgb
bgrbbg
gbgrbb
brbrbgr
rgggb
ggrbgg
brg2
gbgrggr
grbo
rbgbrrb
rbg2
brbgrbr
rggbgb
rbrgo
brrg2
grbgrr
rgbo
bpgbrgb
2bgr3
bogggrr
grrb1
rgbro
rbbrgrg
pbgbrgrb
ogbrp
grrbp
1grb5
bgrg1
g3rbrp
2rr5pgb
g1rbggr
bbgr2
ggrggrb
g1brgbg
2gb3obr
roggbgr
4gboprg
r2bgg3
b1bgr4
5rrbrggg
g4brbo
orrbggbg
b2grbo
2brbrgrg
"""

import os, sys
import readline

readline.parse_and_bind("set editing-mode vim")


def ending():
    play_again = input("Would you like to play again? ")
    if not play_again or play_again[0].lower() != "y":
        sys.exit(2)

    level = input("What level would you like to play? ")
    while not level.isdigit():
        level = input("What level would you like to play? ")

    game(level)


def mapimage(map):
    if map == 0:
        print("  \033[32m__________ ")
        print(" /          \ ")
        print("(            )    ")
        print("\033[35m0\033[31m-----\033[0m1\033[34m------\033[0m2 ")
        print(" \033[34m\   \033[32m/       \033[31m|    ")
        print("  \033[34m\ \033[32m/        \033[31m| ")
        print("   \033[34m\         \033[31m| ")
        print("  \033[32m/ \033[34m\        \033[31m| ")
        print(" \033[32m/   \033[34m\       \033[31m| ")
        print("\033[0m3\033[31m-----\033[0m4\033[32m------\033[0m5 ")
        print("\033[34m(            ) ")
        print(" \          / ")
        print("  ~~~~~~~~~~\033[0m ")
    elif map == 1:
        print("       \033[0m0\033[32m-, ")
        print('      \033[34m/\033[31m|  \033[32m"-, ')
        print('     \033[34m/ \033[31m|     \033[32m"-, ')
        print('    \033[34m/  \033[31m|        \033[32m"-, ')
        print('   \033[34m/   \033[31m|           \033[32m"-, ')
        print('  \033[34m/    \033[31m|              \033[32m"-, ')
        print(' \033[34m/     \033[31m|                 \033[32m"-, ')
        print(
            "\033[33m1\033[32m------\033[35m2\033[34m-------------\033[0m3\033[31m------\033[0m4 "
        )
        print(' \033[31m"-,                 \033[32m|     \033[34m/ ')
        print('    \033[31m"-,              \033[32m|    \033[34m/ ')
        print('       \033[31m"-,           \033[32m|   \033[34m/ ')
        print('          \033[31m"-,        \033[32m|  \033[34m/ ')
        print('             \033[31m"-,     \033[32m| \033[34m/ ')
        print('                \033[31m"-,  \033[32m|\033[34m/ ')
        print('                   \033[31m"-\033[0m5 ')
    elif map == 2:
        print("\033[31m,---------\033[0m1\033[34m------------------\033[0m2 ")
        print("\033[35m0\033[32m---------'              \033[31m,--'\033[32m| ")
        print("\033[34m|                    \033[31m,--'    \033[32m| ")
        print("\033[34m|                \033[31m,--'        \033[32m| ")
        print("\033[34m|            \033[31m,--'            \033[32m| ")
        print("\033[34m|        \033[31m,--'                \033[32m| ")
        print("\033[34m|    \033[31m,--'                    \033[32m| ")
        print("\033[34m|\033[31m,--'            ,-----------\033[0m5 ")
        print("3\033[32m----------------\033[33m4\033[34m-----------'\033[0m ")
    elif map == 3:
        print(" \033[34m_ ")
        print("(/                   \033[35m5 ")
        print("0\033[32m,                  /\033[34m|\033[31m\ ")
        print("|\033[32m|                 / \033[34m| \033[31m\ ")
        print("|\033[32m|                /  \033[34m|  \033[31m\ ")
        print("`\033[0m1\033[34m-,             \033[32m/   \033[34m|   \033[31m\ ")
        print("    \033[34m'--,        \033[32m/    \033[34m|    \033[31m\ ")
        print("        \033[34m'--,   \033[32m/     \033[34m|     \033[31m\ ")
        print(
            "            \033[34m'-\033[0m2\033[31m------\033[0m3\033[32m------\033[0m4 "
        )
        print("                           \033[34m/_\ \033[0m ")
    elif map == 4:
        print("   \033[34m__________________________ ")
        print("  /                          \ ")
        print(" /     \033[32m,--\033[0m1\033[34m-,              \033[31m,--\033[0m4 ")
        print(
            "\033[34m|  \033[32m,--'   \033[31mv  \033[34m'--,      \033[31m,--'    \033[32m'-, "
        )
        print(
            "\033[33m0\033[32m-'       \033[31mv      \033[34m'-\033[35m3\033[31m--'           \033[32m'-, "
        )
        print("\033[31m|         v      \033[32m,-'                 '-, ")
        print("\033[31m|         v   \033[32m,-'                       '-, ")
        print("\033[31m(         v\033[32m,-'                             ', ")
        print(
            " \033[31m\        \033[0m2\033[34m----------------------------------\033[0m5 "
        )
        print("  \033[31m\                                          | ")
        print("   '-----------------------------------------'\033[0m ")
    elif map == 5:
        print(
            "           \033[31m,--\033[33m1\033[34m-----------------------\033[0m3\033[31m--, "
        )
        print("          > v \033[32m^>                     <^ \033[31mv < ")
        print("         >  v \033[32m^ >                   < ^ \033[31mv  < ")
        print("        >   v \033[32m^  >                 <  ^ \033[31mv   < ")
        print("       >    v \033[32m^   >               <   ^ \033[31mv    < ")
        print("      >     v \033[32m^    >             <    ^ \033[31mv     < ")
        print("     >      v \033[32m^     >           <     ^ \033[31mv      < ")
        print("    >       v \033[32m^      >         <      ^ \033[31mv       < ")
        print("   >        v \033[32m^       >       <       ^ \033[31mv        < ")
        print("  >         v \033[32m^        >     <        ^ \033[31mv         < ")
        print(" >          v \033[32m^         >   <         ^ \033[31mv          < ")
        print(
            "\033[0m0           \033[31mv \033[32m^          > <          ^ \033[31mv           \033[0m5 "
        )
        print(
            " \033[31m<          v \033[32m^           <           ^ \033[31mv          > "
        )
        print(
            "  <         v \033[32m^          < >          ^ \033[31mv         >              "
        )
        print("   <        v \033[32m^         <   >         ^ \033[31mv        > ")
        print("    <       v \033[32m^        <     >        ^ \033[31mv       > ")
        print("     <      v \033[32m^       <       >       ^ \033[31mv      > ")
        print("      <     v \033[32m^      <         >      ^ \033[31mv     > ")
        print("       <    v \033[32m^     <           >     ^ \033[31mv    > ")
        print("        <   v \033[32m^    <             >    ^ \033[31mv   > ")
        print("         <  v \033[32m^   <               >   ^ \033[31mv  > ")
        print("          < v \033[32m^  <                 >  ^ \033[31mv > ")
        print(
            "           `--\033[35m2\033[34m-----------------------\033[33m4\033[31m--'\033[0m "
        )
    elif map == 6:
        print("             \033[34m,-\033[0m2\033[31m-, ")
        print("         \033[34m,--'  \033[32m|  \033[31m'--, ")
        print("     \033[34m,--'      \033[32m|      \033[31m'--, ")
        print(" \033[34m,--'          \033[32m|          \033[31m'--, ")
        print(
            "\033[33m0\033[31m-,            \033[32m|              \033[0m5\033[32m---------------\033[0m7 "
        )
        print(
            "\033[32m|  \033[31m'--,        \033[32m|              \033[34m|               | "
        )
        print(
            "\033[32m|      \033[31m'--,    \033[32m|              \033[34m|               | "
        )
        print(
            "\033[32m|          \033[31m'-, \033[32m|              \033[34m|               | "
        )
        print(
            "\033[32m|             \033[31m'\033[0m3              \033[34m|               | "
        )
        print("\033[32m|              \033[34m|              |               | ")
        print("\033[32m|              \033[34m|              |               | ")
        print(
            "\033[0m1\033[31m,             \033[34m|             \033[32m,\033[0m6\033[31m---------------\033[0m8 "
        )
        print("  \033[31m'-,          \033[34m|          \033[32m,-'  ")
        print("     \033[31m'--,      \033[34m|      \033[32m,--' ")
        print("         \033[31m'--,  \033[34m|  \033[32m,--' ")
        print("             \033[31m'-\033[0m4\033[32m-'\033[0m ")
    elif map == 7:
        print("               \033[31m_ ")
        print("              \ / ")
        print("             \033[32m,-\033[0m0\033[34m-, ")
        print("          \033[32m,-'     \033[34m'-, ")
        print("         \033[0m1\033[32m-<-<-<-<-<-\033[0m2 ")
        print("        \033[31m<   \033[34m'-, \033[31m,-'   \033[32m<  ")
        print("       \033[31m<       \033[33m3       \033[32m<  ")
        print("      \033[31m<       \033[31m> \033[32m>       <  ")
        print("     \033[31m<       \033[31m>   \033[32m>       <  ")
        print("    \033[31m<       \033[31m>     \033[32m>       <  ")
        print("   \033[31m<       \033[31m>       \033[32m>       <  ")
        print("  \033[31m<       \033[31m>         \033[32m>       <, ")
        print(
            " \033[0m4\033[34m-------\033[0m5\033[34m-<-<-<-<-<-\033[0m6\033[31m--------\033[0m7 "
        )
        print(" \033[32m|\033[31m>      \033[32m|           |       \033[34m>| ")
        print(" \033[32m| \033[31m>     \033[32m|           |      \033[34m> | ")
        print(" \033[32m|  \033[31m>    \033[32m|           |     \033[34m>  | ")
        print(" \033[32m|   \033[31m>   \033[32m|           |    \033[34m>   | ")
        print(" \033[32m|    \033[31m>  \033[32m|           |   \033[34m>    | ")
        print(" \033[32m|     \033[31m> \033[32m|           |  \033[34m>     | ")
        print(" \033[32m|      \033[31m>\033[32m|           | \033[34m>      | ")
        print(
            " \033[0m8\033[31m-------\033[33m9\033[34m->->->->->-\033[33m10\033[31m-------\033[0m11 "
        )
        print("\033[34m/_\                          \033[32m/_|\033[0m ")
    elif map == 8:
        print("     \033[32m,------\033[0m0\033[31m------, ")
        print("    \033[32m/      \033[34m< \033[32m<      \033[31m\ ")
        print("   \033[32m/      \033[34m<   \033[32m<      \033[31m\ ")
        print("  \033[32m/      \033[34m<     \033[32m<      \033[31m\ ")
        print(" \033[32m/   ,--\033[33m1\033[31m->->->-\033[0m2\033[31m--,   \ ")
        print(
            "\033[32m(   /  \033[34m< \033[32m<     \033[34m< \033[32m<  \033[31m\   ) "
        )
        print(
            "\033[32m|  (  \033[34m<   \033[32m<   \033[34m<   \033[32m<  \033[31m)  | "
        )
        print(
            "\033[32m|  | \033[34m<     \033[32m< \033[34m<     \033[32m< \033[31m|  | "
        )
        print(
            "\033[32m|  '\033[0m3\033[31m->->->-\033[0m4\033[31m->->->-\033[0m5\033[31m'  | "
        )
        print(
            "\033[32m|  \033[34m< \033[32m<     \033[34m< \033[32m<     \033[34m< \033[32m<  \033[31m| "
        )
        print(
            "\033[32m| \033[34m<   \033[32m<   \033[34m<   \033[32m<   \033[34m<   \033[32m< \033[31m| "
        )
        print(
            "\033[32m|\033[34m<     \033[32m< \033[34m<     \033[32m< \033[34m<     \033[32m<\033[31m| "
        )
        print(
            "\033[0m6\033[31m->->->-\033[0m7\033[31m->->->-\033[0m8\033[31m->->->-\033[0m9 "
        )
        print("\033[34m(       '-------'       ) ")
        print(" \                     / ")
        print("  '-------------------'\033[0m ")
    elif map == 9:
        print("            \033[31m_ ")
        print("           \ / ")
        print("          \033[32m,-\033[0m2\033[34m-, ")
        print("     \033[31m,-\033[0m1\033[32m-'     \033[34m'-\033[0m3\033[31m-, ")
        print(
            " \033[34m,\033[0m0\033[31m-'   \033[34m\       \033[32m/   \033[31m'-\033[35m4\033[32m, "
        )
        print(
            "\033[34m^ \033[32mv      \033[34m\     \033[32m/      \033[34m^ \033[32mv "
        )
        print(
            "\033[34m^ \033[32mv       \033[0m5\033[31m---\033[0m6       \033[34m^ \033[32mv "
        )
        print("\033[34m^ \033[32mv      /     \033[34m\      ^ \033[32mv ")
        print(
            " \033[34m'\033[33m7\033[31m-,   \033[32m/       \033[34m\   \033[31m,\033[0m11\033[32m' "
        )
        print("     \033[31m'-\033[0m8\033[34m-,     \033[32m,\033[33m10\033[31m-' ")
        print("          \033[34m'-\033[0m9\033[32m-' ")
        print("           \033[31m/_\ \033[0m ")


def move(color, map, avatar_position):
    try:
        new_position = map[avatar_position][color]
        print("Moving from %d to %d" % (avatar_position, new_position))
        return position
    except TypeError:
        print("No path that way, you lose.\nTry again.")
        ending()


def scrollimage(scroll):
    if scroll == 0:
        print("                                                   ____ ")
        print("   O       __        __        __        __      .' __ `. ")
        print("  /H\    ,'  `.    ,'  `.    ,'  `.    ,'  `.    | /.,\ | ")
        print(" / H \=> |  0 | => |  1 | => |  2 | => |  3 | => |{_,' }| ")
        print("  / \    '.__.'    '.__.'    '.__.'    '.__.'    | ,__/ | ")
        print(" /   \                                           '.____.' ")
        print("                                                 /______\ ")
    elif scroll == 1:
        print("                                                             ____ ")
        print("   O       __        __        __        __        __      .' __ `. ")
        print("  /H\    ,'  `.    ,'  `.    ,'  `.    ,'  `.    ,'  `.    | /.,\ | ")
        print(" / H \=> |  0 | => |  1 | => |  2 | => |  3 | => |  4 | => |{_,' }| ")
        print("  / \    '.__.'    '.__.'    '.__.'    '.__.'    '.__.'    | ,__/ | ")
        print(" /   \                                                     '.____.' ")
        print("                                                           /______\ ")
    elif scroll == 2:
        print(
            "                                                                       ____ "
        )
        print(
            "   O       __        __        __        __        __        __      .' __ `. "
        )
        print(
            "  /H\    ,'  `.    ,'  `.    ,'  `.    ,'  `.    ,'  `.    ,'  `.    | /.,\ | "
        )
        print(
            " / H \=> |  0 | => |  1 | => |  2 | => |  3 | => |  4 | => |  5 | => |{_,' }| "
        )
        print(
            "  / \    '.__.'    '.__.'    '.__.'    '.__.'    '.__.'    '.__.'    | ,__/ | "
        )
        print(
            " /   \                                                               '.____.' "
        )
        print(
            "                                                                     /______\ "
        )
    elif scroll == 3:
        print("           <-<-<-<-<-<-<-<-<-<-<-<-<-<-<-< ")
        print("           |                             | ")
        print("           v                             \033[31mF\033[0m         ____ ")
        print("   O       __        __        __        ^^      .' __ `. ")
        print("  /H\    ,'  `.    ,'  `.    ,'  `.     /  \     | /.,\ | ")
        print(
            " / H \=> |  0 | => |  1 | => |  2 | => |  3 |\033[32mT\033[0m=> |{_,' }| "
        )
        print("  / \    '.__.'    '.__.'    '.__.'     \  /     | ,__/ | ")
        print(" /   \                                   vv      '.____.' ")
        print("                                                 /______\ ")
    elif scroll == 4:
        print(
            "                                                                                 ____ "
        )
        print(
            "   O       __        __        __        __        __        __        __      .' __ `. "
        )
        print(
            "  /H\    ,'  `.    ,'  `.    ,'  `.    ,'  `.    ,'  `.    ,'  `.    ,'  `.    | /.,\ | "
        )
        print(
            " / H \=> |  0 | => |  1 | => |  2 | => |  3 | => |  4 | => |  5 | => |  6 | => |{_,' }| "
        )
        print(
            "  / \    '.__.'    '.__.'    '.__.'    '.__.'    '.__.'    '.__.'    '.__.'    | ,__/ | "
        )
        print(
            " /   \                                                                         '.____.' "
        )
        print(
            "                                                                               /______\ "
        )
    elif scroll == 5:
        print("           <-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<- ")
        print("           |                                      | ")
        print(
            "           v                                      \033[32mT\033[0m          ____  "
        )
        print("   O       __        __        __       __        ^^       .' __ `. ")
        print("  /H\    ,'  `.    ,'  `.    ,'  `.   ,'  `.     /  \      | /.,\ | ")
        print(
            " / H \=> |  0 | => |  1 | => |  2 | = |  3 | => |  4 | \033[31mF\033[0m=> |{_,' }| "
        )
        print("  / \    '.__.'    '.__.'    '.__.'   '.__.'     \  /      | ,__/ | ")
        print(" /   \                                            vv       '.____.' ")
        print("                                                           /______\ ")
    elif scroll == 6:
        print("                     <-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<- ")
        print("                     |                              | ")
        print("                     v                              | ")
        print("   O       __        ^^         __        __        |_")
        print("  /H\    ,'  `.     /  \      ,'  `.    ,'  `.    .'  `. ")
        print(
            " / H \=> |  0 | => |  1 | \033[32mT\033[0m=> |  2 | => |  3 | => |  4 | "
        )
        print("  / \    '.__.'     \  /      '.__.'    '.__.'    '.__.' ")
        print(" /   \               vv                           ____ ")
        print(
            "                      \033[31mF\033[0m       __        __      .' __ `. "
        )
        print("                      |     .'  `.    .'  `.    | /.,\ | ")
        print("                      >->-> |  5 | => |  6 | => |{_,' }| ")
        print("                            '.__.'    '.__.'    | ,__/ | ")
        print("                                                '.____.' ")
        print("                                                /______\ ")
    elif scroll == 7:
        print("          <-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-< ")
        print("          |                                   | ")
        print("          |                __                 | ")
        print("          |              ,'  `.               | ")
        print("          |      >->->-> |  1 | >->->         | ")
        print("          |      |       '.__.'     |         | ")
        print(
            "          |      \033[32mT\033[0m                  |         \033[31mF\033[0m         ____ "
        )
        print("   O      |     ^^                 _v        ^^       .' __ `. ")
        print("  /H\     |    /  \              ,'  `.     /  \      | /.,\ | ")
        print(
            " / H \   ===> |  0 |             |  3 | => |  4 |\033[32mT\033[0m=>  |{_,' }| "
        )
        print("  / \          \  /              '.__.'     \  /      | ,__/ | ")
        print(" /   \          vv                  ^        vv       '.____.' ")
        print(
            "                 \033[31mF\033[0m       __         |                 /______\ "
        )
        print("                 |     .'  `.       | ")
        print("                 >->-> |  2 | >->->-> ")
        print("                       '.__.' ")
    elif scroll == 8:
        print("           <-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<- ")
        print("           |                                        | ")
        print("           v                                        | ")
        print("   O       ^^         __        __        __        |_")
        print("  /H\     /  \      ,'  `.    ,'  `.    ,'  `.    .'  `. ")
        print(
            " / H \=> |  0 | \033[31mF\033[0m=> |  1 | => |  2 | => |  3 | => |  4 | "
        )
        print("  / \     \  /      '.__.'    '.__.'    '.__.'    '.__.' ")
        print(" /   \     vv                                     ____ ")
        print(
            "            \033[32mT\033[0m       __        __        __      .' __ `. "
        )
        print("            |     .'  `.    .'  `.    ,'  `.    | /.,\ | ")
        print("            >->-> |  5 | => |  6 | => |  7 | => |{_,' }| ")
        print("                  '.__.'    '.__.'    '.__.'    | ,__/ | ")
        print("                                                '.____.' ")
        print("                                                /______\ ")
    elif scroll == 9:
        print("           <-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<- ")
        print("           |                                      | ")
        print(
            "           v                                      \033[31mF\033[0m          ____ "
        )
        print("   O       __        __        __       __        ^^       .' __ `. ")
        print("  /H\    ,'  `.    ,'  `.    ,'  `.   ,'  `.     /  \      | /.,\ | ")
        print(
            " / H \=> |  0 | => |  1 | => |  2 | = |  3 | => |  4 | \033[32mT\033[0m=> |{_,' }| "
        )
        print("  / \    '.__.'    '.__.'    '.__.'   '.__.'     \  /      | ,__/ | ")
        print(" /   \                                            vv       '.____.' ")
        print("                                                           /______\ ")
    elif scroll == 10:
        print("            <-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-< ")
        print("            |                                       | ")
        print("            |                    __                 | ")
        print("            |                  ,'  `.               | ")
        print("            |          >->->-> |  2 | >->->         | ")
        print("            |          |       '.__.'     |         | ")
        print(
            "            |          \033[32mT\033[0m                  |         \033[31mF\033[0m         ____ "
        )
        print("   O        |_        ^^                 _v        ^^       .' __ `. ")
        print("  /H\     ,'  `.     /  \              ,'  `.     /  \      | /.,\ | ")
        print(
            " / H \ => |  0 | => |  1 |             |  4 | => |  5 |\033[32mT\033[0m=>  |{_,' }| "
        )
        print("  / \     '.__.'     \  /              '.__.'     \  /      | ,__/ | ")
        print(" /   \                vv                  ^        vv       '.____.' ")
        print(
            "                       \033[31mF\033[0m       __         |                 /______\ "
        )
        print("                       |     .'  `.       | ")
        print("                       >->-> |  3 | >->->-> ")
        print("                             '.__.' ")
    elif scroll == 11:
        print("                 <-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-<-< ")
        print("                 |                                 | ")
        print("                 v                                 \033[31mF\033[0m ")
        print("   O            ^^        __            __        ^^ ")
        print("  /H\          /  \     ,'  `.        ,'  `.     /  \ ")
        print(" / H \   ===> |  0 |\033[32mT\033[0m=> |  1 | =>->-> |  2 | => |  3 | ")
        print("  / \          \  /     '.__.'    |   '.__.'     \  / ")
        print(" /   \          vv                |      ^        vv ")
        print(
            "                 \033[31mF\033[0m                |      |         \033[32mT\033[0m "
        )
        print("                 |     ^^        _|      |         | ")
        print("                 |    /  \     ,'  `.    |         v ")
        print("                 >-> |  4 |\033[32mT\033[0m=> |  5 |    |       ____ ")
        print("                      \  /     '.__.'    |     .' __ `. ")
        print("                       vv                |     | /.,\ | ")
        print("                        \033[31mF\033[0m               _|     |{_,' }| ")
        print("                        |             ,'  `.   | ,__/ | ")
        print("                        >->->->->->-> |  6 |   '.____.' ")
        print("                                      '.__.'   /______\ ")


def game(level_number="NaN"):
    maps = [
        [
            [1, 4, 2, 1],
            [0, 2, 3, 0],
            [5, 1, 0, 0],
            [4, 5, 1, 0],
            [3, 0, 5, 0],
            [2, 3, 4, 2],
        ],
        [
            [2, 1, 4, 0],
            [5, 0, 2, 2],
            [0, 3, 1, 1],
            [4, 2, 5, 0],
            [3, 5, 0, 0],
            [1, 4, 3, 0],
        ],
        [
            [1, 3, 1, 1],
            [0, 2, 0, 0],
            [3, 1, 5, 1],
            [2, 0, 4, 0],
            [5, 5, 3, 2],
            [4, 4, 2, 0],
        ],
        [
            [1, 0, 1, 1],
            [0, 2, 0, 0],
            [3, 1, 5, 0],
            [2, 5, 4, 0],
            [5, 4, 3, 0],
            [4, 3, 2, 1],
        ],
        [
            [5, 4, 1, 2],
            [2, 3, 0, 0],
            [None, 5, 3, 0],
            [4, 1, 2, 1],
            [3, 0, 5, 0],
            [0, 2, 4, 0],
        ],
        [
            [1, None, None, 0],
            [2, 3, 4, 2],
            [0, 4, 1, 1],
            [4, 1, 2, 0],
            [5, 2, 3, 2],
            [3, None, None, 0],
        ],
        [
            [3, 2, 1, 2],
            [4, None, 0, 0],
            [5, 0, 3, 0],
            [0, 4, 2, 0],
            [1, 3, 6, 0],
            [2, 6, 7, 0],
            [8, 5, 4, 0],
            [None, 8, 5, 0],
            [6, 7, None, 0],
        ],
        [
            [0, 2, 1, 0],
            [4, 3, 0, 0],
            [3, 0, 1, 0],
            [2, 1, 6, 2],
            [9, 5, 8, 0],
            [3, 4, 9, 0],
            [7, 5, 10, 0],
            [6, 11, 2, 0],
            [9, 8, 4, 0],
            [8, 10, 5, 2],
            [11, 7, 6, 2],
            [10, 7, 11, 0],
        ],
        [
            [9, 1, 6, 0],
            [2, 3, 3, 2],
            [5, 4, 0, 0],
            [4, 6, 1, 0],
            [5, 7, 1, 0],
            [2, 8, 2, 0],
            [7, 9, 0, 0],
            [8, 8, 3, 0],
            [9, 7, 4, 0],
            [0, 6, 5, 0],
        ],
        [
            [1, None, 7, 0],
            [0, 5, 2, 0],
            [2, 3, 1, 0],
            [4, 2, 6, 0],
            [3, None, 11, 1],
            [6, 1, 8, 0],
            [5, 10, 3, 0],
            [8, 0, None, 2],
            [7, 9, 5, 0],
            [9, 8, 10, 0],
            [11, 6, 9, 2],
            [10, 4, None, 0],
        ],
    ]

    scrolls = [
        [4, {}],
        [5, {}],
        [6, {}],
        [4, {3: (4, 0)}],
        [7, {}],
        [5, {4: (0, 5)}],
        [7, {1: (2, 5), 4: 1}],
        [5, {0: (1, 2), 1: 3, 4: (5, 0)}],
        [8, {0: (5, 1), 4: 0}],
        [5, {4: (5, 0)}],
        [6, {1: (2, 3), 2: 4, 5: (6, 0)}],
        [7, {0: (1, 4), 3: (7, 0), 4: (5, 6), 5: 2, 6: 2}],
    ]

    levels = [
        [0, 0, 5, 3, None, None, {0: 2, 1: 0, 2: 2}],
        [1, 0, 3, 5, [0], None, {0: 2, 1: 2, 2: 0}],
        [2, 0, 4, 0, [1, 5], None, {0: 1, 1: 2, 2: 1}],
        [3, 1, 1, 5, [3, 4], None, {0: 2, 1: 2, 2: 1}],
        [4, 0, 2, 5, [3], None, {0: 1, 1: 2, 2: 1}],
        [5, 1, 5, 0, [1, 4], None, {0: 2, 1: 2, 2: 1}],
        [6, 1, 0, 8, None, None, {0: 2, 1: 1, 2: 2}],
        [7, 0, 7, 4, None, None, {0: 2, 1: 1, 2: 1}],
        [8, 1, 9, 4, [0, 7], None, {0: 2, 1: 1, 2: 2}],
        [9, 2, 2, 6, None, None, {0: 3, 1: 2, 2: 1}],
        [0, 0, 2, 4, [1], None, {0: 2, 1: 1, 2: 1}],
        [1, 1, 5, 0, None, None, {0: 2, 1: 1, 2: 2}],
        [2, 1, 5, 0, [4, 4], None, {0: 3, 1: 1, 2: 1}],
        [3, 1, 0, 4, [4, 4, 5], None, {0: 1, 1: 2, 2: 2}],
        [4, 1, 4, 0, [2, 5], None, {0: 2, 1: 2, 2: 1}],
        [5, 3, 1, 3, [2, 2, 2, 4, 4, 4], [6], {0: 1, 1: 1, 2: 1}],
        [6, 2, 3, 5, [0, 4], None, {0: 1, 1: 2, 2: 3}],
        [7, 2, 9, 2, [11], None, {0: 1, 1: 3, 2: 2}],
        [8, 2, 2, 8, [0, 4], None, {0: 1, 1: 3, 2: 2}],
        [9, 4, 6, 0, [2], None, {0: 3, 1: 3, 2: 1}],
        [0, 1, 0, 5, [1, 1], None, {0: 1, 1: 1, 2: 3}],
        [1, 2, 5, 0, [3, 4], None, {0: 1, 1: 1, 2: 4}],
        [2, 3, 2, 4, [1, 3], [2], {0: 1, 1: 1, 2: 1}],
        [3, 4, 0, 5, [4, 4, 5, 5], None, {0: 2, 1: 1, 2: 4}],
        [4, 3, 5, 0, None, ["o"], {0: 1, 1: 1, 2: 1}],
        [5, 4, 0, 1, [2, 3, 3, 4], None, {0: 3, 1: 3, 2: 1}],
        [6, 3, 0, 1, [2, 5], [2], {0: 1, 1: 1, 2: 1}],
        [7, 4, 9, 4, [2], None, {0: 3, 1: 3, 2: 1}],
        [8, 2, 5, 8, [6, 9], None, {0: 1, 1: 2, 2: 3}],
        [9, 5, 6, 6, [3], ["o"], {0: 2, 1: 1, 2: 1}],
        [0, 5, 2, 4, [1, 1, 5], [2], {0: 2, 1: 1, 2: 1}],
        [1, 2, 4, 5, [0, 1, 5, 5], None, {0: 3, 1: 1, 2: 2}],
        [2, 3, 1, 4, [3, 3, 3], ["o"], {0: 1, 1: 1, 2: 1}],
        [3, 6, 3, 4, [1, 4, 4], ["p"], {0: 1, 1: 3, 2: 2}],
        [4, 7, 4, 0, [2, 5, 5], [2, 3], {0: 1, 1: 1, 2: 1}],
        [5, 6, 2, 1, [0, 3, 3], ["o"], {0: 2, 1: 1, 2: 3}],
        [6, 5, 1, 5, [3, 8], [1], {0: 2, 1: 1, 2: 1}],
        [7, 5, 8, 2, [1], ["o"], {0: 2, 1: 1, 2: 1}],
        [8, 4, 3, 0, [2, 4, 9], None, {0: 3, 1: 2, 2: 2}],
        [9, 8, 8, 6, [2, 4, 9, 11], ["p"], {0: 2, 1: 3, 2: 2}],
        [0, 7, 1, 0, [2, 3, 4], ["o", "p"], {0: 1, 1: 1, 2: 1}],
        [1, 9, 0, 2, [3, 3, 3, 4, 4, 4], ["p"], {0: 2, 1: 1, 2: 1}],
        [2, 7, 5, 3, [0, 1, 2, 3, 4], [1, 5], {0: 1, 1: 1, 2: 1}],
        [3, 5, 2, 3, [0, 4, 5], [1], {0: 1, 1: 1, 2: 2}],
        [4, 10, 2, 3, [1, 1, 1], [3, "p"], {0: 2, 1: 1, 2: 1}],
        [5, 11, 3, 4, [0, 1, 1, 1, 4], [2, 5, "p"], {0: 2, 1: 1, 2: 1}],
        [6, 6, 0, 8, [1, 6], [1], {0: 2, 1: 1, 2: 3}],
        [7, 9, 1, 3, [6, 11], [2], {0: 1, 1: 2, 2: 1}],
        [8, 4, 1, 8, [2, 3, 6], None, {0: 2, 1: 1, 2: 4}],
        [9, 6, 8, 11, [4, 4, 5, 11, 11], [1], {0: 1, 1: 2, 2: 3}],
        [0, 11, 4, 0, [0, 5, 5], [2, 3, "o"], {0: 1, 1: 2, 2: 1}],
        [1, 6, 5, 3, [0, 1, 1, 2, 4], ["o"], {0: 2, 1: 1, 2: 3}],
        [2, 11, 4, 4, [0, 0, 2, 2], [4, "o", "p"], {0: 1, 1: 1, 2: 2}],
        [3, 10, 3, 0, [1, 4, 5], [2, 3], {0: 1, 1: 1, 2: 2}],
        [4, 10, 0, 5, [1, 1, 4, 5], [1, 4], {0: 1, 1: 2, 2: 1}],
        [5, 8, 4, 1, [1, 1, 2, 2, 3, 3], [5], {0: 3, 1: 1, 2: 3}],
        [6, 10, 0, 0, [2, 3, 3, 4, 5, 7], [4, "o"], {0: 1, 1: 2, 2: 1}],
        [7, 8, 5, 8, [0, 9, 10], ["o"], {0: 2, 1: 2, 2: 3}],
        [8, 10, 0, 1, [2, 5, 7, 7, 7], [2, "o"], {0: 1, 1: 2, 2: 1}],
        [9, 8, 8, 9, [2, 9], [2], {0: 3, 1: 2, 2: 2}],
    ]

    if not level_number.isdigit():
        level_number = input("What level would you like to play? ")
        while not level_number.isdigit():
            level_number = input("What level would you like to play? ")
        if int(level_number) < 1 or int(level_number) > 60:
            print("Not a level")
            ending()
        level = levels[int(level_number) - 1]
    else:
        if int(level_number) < 1 or int(level_number) > 60:
            print("Not a level")
            ending()
        level = levels[int(level_number) - 1]

    map = maps[level[0]]
    scroll = scrolls[level[1]]
    avatar_position = level[2]
    portal_position = level[3]
    crystal_positions = level[4]
    if crystal_positions:
        crystals_count = len(crystal_positions)
    else:
        crystals_count = 0
    modifier_tokens = level[5]
    commands_available = level[6]

    os.system("clear")
    print("You are playing on map %d with scroll %d\n" % (level[0] + 1, level[1] + 1))
    mapimage(level[0])
    print(
        "\nYou are starting at %d and the portal is at %d\n"
        % (avatar_position, portal_position)
    )
    print("There are crystals in these locations: " + str(crystal_positions))
    print("You have these mods: " + str(modifier_tokens))
    print(
        "You have %d reds, %d blues, and %d greens"
        % (commands_available[0], commands_available[1], commands_available[2])
    )
    scrollimage(level[1])

    commands = input("Please input the order of tokens (rbg123456op): ")
    while len(commands) != scroll[0]:
        commands = input("Please input the order of tokens (rbg123456op): ")

    # Ensure that the input is valid given tokens in play
    if commands.count("r") != commands_available[0]:
        print("Not a valid command sequence")
        ending()
    elif commands.count("b") != commands_available[1]:
        print("Not a valid command sequence")
        ending()
    elif commands.count("g") != commands_available[2]:
        print("Not a valid command sequence")
        ending()
    if modifier_tokens:
        for token in modifier_tokens:
            if commands.count(str(token)) != 1:
                print("Not a valid command sequence")
                ending()

    # begin level
    scrollp = 0
    crystals = 0
    rotation = 0

    while scrollp < scroll[0] and rotation < 80:
        rotation += 1

        if scrollp in scroll[1]:
            if isinstance(scroll[1][scrollp], tuple):
                # Ensure conditional in this position of commands and then test
                if commands[scrollp] not in "123456op":
                    print("There should be a conditional at " + str(scrollp))
                    ending()

                if commands[scrollp] == "1":
                    if crystals == 1:
                        print("You have 1 crystal!")
                        scrollp = scroll[1][scrollp][0]
                        continue
                    else:
                        print("You do not have 1 crystal!")
                        scrollp = scroll[1][scrollp][1]
                        continue
                elif commands[scrollp] == "2":
                    if crystals == 2:
                        print("You have 2 crystals!")
                        scrollp = scroll[1][scrollp][0]
                        continue
                    else:
                        print("You do not have 2 crystals!")
                        scrollp = scroll[1][scrollp][1]
                        continue
                elif commands[scrollp] == "3":
                    if crystals == 3:
                        print("You have 3 crystals!")
                        scrollp = scroll[1][scrollp][0]
                        continue
                    else:
                        print("You do not have 3 crystals!")
                        scrollp = scroll[1][scrollp][1]
                        continue
                elif commands[scrollp] == "4":
                    if crystals == 4:
                        print("You have 4 crystals!")
                        scrollp = scroll[1][scrollp][0]
                        continue
                    else:
                        print("You do not have 4 crystals!")
                        scrollp = scroll[1][scrollp][1]
                        continue
                elif commands[scrollp] == "5":
                    if crystals == 5:
                        print("You have 5 crystals!")
                        scrollp = scroll[1][scrollp][0]
                        continue
                    else:
                        print("You do not have 5 crystals!")
                        scrollp = scroll[1][scrollp][1]
                        continue
                elif commands[scrollp] == "6":
                    if crystals == 6:
                        print("You have 6 crystals!")
                        scrollp = scroll[1][scrollp][0]
                        continue
                    else:
                        print("You do not have 6 crystals!")
                        scrollp = scroll[1][scrollp][1]
                        continue
                elif commands[scrollp] == "o":
                    if map[avatar_position][3] == 2:
                        print("This is an orange spot!")
                        scrollp = scroll[1][scrollp][0]
                        continue
                    else:
                        print("This is not an orange spot!")
                        scrollp = scroll[1][scrollp][1]
                        continue
                elif commands[scrollp] == "p":
                    if map[avatar_position][3] == 1:
                        print("This is a purple spot!")
                        scrollp = scroll[1][scrollp][0]
                        continue
                    else:
                        print("This is not a purple spot!")
                        scrollp = scroll[1][scrollp][1]
                        continue
            else:
                # else run command and then move scrollp to new destination
                if commands[scrollp] == "r":
                    avatar_position = move(0, map, avatar_position)
                elif commands[scrollp] == "b":
                    avatar_position = move(1, map, avatar_position)
                elif commands[scrollp] == "g":
                    avatar_position = move(2, map, avatar_position)
                else:
                    print("Can't use a conditional here")
                    ending()
                scrollp = scroll[1][scrollp]
        else:
            if commands[scrollp] == "r":
                avatar_position = move(0, map, avatar_position)
            elif commands[scrollp] == "b":
                avatar_position = move(1, map, avatar_position)
            elif commands[scrollp] == "g":
                avatar_position = move(2, map, avatar_position)
            else:
                print("Can't use a conditional here")
                ending()
            scrollp += 1

        if crystals_count != 0:
            if avatar_position in crystal_positions:
                print("You picked up a crystal!")
                crystals += 1
                crystal_positions.remove(avatar_position)

    if avatar_position == portal_position:
        if crystals == crystals_count:
            print("You win the level!")
            ending()

    print("You lose, try again")
    ending()


if __name__ == "__main__":
    if len(sys.argv) == 2:
        game(sys.argv[1])
    else:
        game()
