#!/usr/bin/python3
"""
An old game whose name is significant.

Author: Joshua Snider
"""

from optparse import OptionParser
import os
import random
import sys
import time

usage = "Usage: python3 petalsAroundTheRose.py [-n|--bastard-mode]"
parser = OptionParser(usage=usage)
parser.add_option('-n','--bastard-mode',action='store_true',dest='bastard')
parser.set_defaults(bastard=False)
(options,args) = parser.parse_args()

bone1 = ["|         |",
         "|       o |",
         "|       o |",
         "| o     o |",
         "| o     o |",
         "| o     o |"]
bone2 = ["|    o    |",
         "|         |",
         "|    o    |",
         "|         |",
         "|    o    |",
         "| o     o |"]
bone3 = ["|         |",
         "| o       |",
         "| o       |",
         "| o     o |",
         "| o     o |",
         "| o     o |"]
bone = "+---------+"

wins = 0
dice = [0,1,2,3,4]
petals = {3:2,5:4}
motd = """\033[94m
The name of the game is Petals Around the Rose,
and that name is significant.
Five dice will roll and you must guess the "answer" for each roll.
It will be zero or an even number.
After your guess, you will be told the answer for the roll, but . . .
that's ALL the information you will get.

Six consecutive correct guesses admits you to the
Fellowship of the Rose.
\033[0m"""

def fortune():
  return random.choice(range(1,7))

def throw():
  rose = 0
  for i in range(0,5):
    dice[i] = fortune()
  for die in dice:
    try:
      rose += petals[die]
    except KeyError:
      pass
  os.system('cls' if os.name == 'nt' else 'clear')
  print('\n'+bone+'\t'+bone+'\t'+bone+'\t'+bone+'\t'+bone)
  print(bone1[dice[0]-1]+'\t'+bone1[dice[1]-1]+'\t'+bone1[dice[2]-1]+'\t'+\
        bone1[dice[3]-1]+'\t'+bone1[dice[4]-1])
  print(bone2[dice[0]-1]+'\t'+bone2[dice[1]-1]+'\t'+bone2[dice[2]-1]+'\t'+\
        bone2[dice[3]-1]+'\t'+bone2[dice[4]-1])
  print(bone3[dice[0]-1]+'\t'+bone3[dice[1]-1]+'\t'+bone3[dice[2]-1]+'\t'+\
        bone3[dice[3]-1]+'\t'+bone3[dice[4]-1])
  print(bone+'\t'+bone+'\t'+bone+'\t'+bone+'\t'+bone+'\n\n')
  return rose

def game():
  rose = throw()
  guess = input('There are how many petals around the rose? ')
  while not guess.isdigit():
    guess = input("\n\tI'm gonna need an integer, pal: ")
  return rose, guess

try:
  os.system('cls' if os.name == 'nt' else 'clear')
  ins = input('Do you need instructions?')
  if len(ins) > 1:
    ins = ins[0].lower()
  if ins == 'y':
    os.system('cls' if os.name == 'nt' else 'clear')
    print(motd)
    time.sleep(1)
    os.system('cls' if os.name == 'nt' else 'clear')
  while wins < 6:
    rose, guess = game()
    if str(rose) == guess:
      print('Correct. There are '+str(rose)+' petals around the rose.\n')
      wins += 1
      if wins == 6:
        print('\033[91;1mYou have unraveled the mystery of the Rose Petals!')
        print('Welcome to the Fellowship of the Rose!!!')
        print('(You are herewith sworn to secrecy.)\n\033[0m')
        sys.exit(0)
      else:
        print('You have '+str(wins)+' correct so far.\n')
      if wins == 5:
        print('Just one more gets you to the heart of the mystery!\n')
    elif options.bastard:
      print("\nWrong, and I won't tell you how many there are cuz I'm a bastard! =)\n")
      wins = 0
    else:
      print('\nWrong. There are '+str(rose)+' petals around the rose.\n')
      wins = 0
    cont = input('Hit ENTER for the next roll, or type "exit" to end.')
    if cont == 'exit':
      sys.exit(98)
except EOFError:
  print('\nGoodbye.')
  sys.exit(99)
