#!/bin/bash

## State: Doesn't actually work yet, but does make _something_
## that's headed in the right direction


## Generate a directory structure using a template like the output of
## tree. Would be cool to add Unicode support for piping tree directly
## into this.

## The basics are that there is a root, and each level under root is
## successively indented by three characters, made up of pipes (|),
## spaces ( ), and dashes (-).

## ASSUMPTIONS
# The directory names start with a character in the POSIX word character
# set.

## BUGS (- = closed; o = open)
# - Current working directory needs to be known before we start it seems
#    The name given to mkdir gets a leading slash somehow, ./ in front
#    isn't the most elegant solution but it works.
# - The append to the array may not be working correctly
#    Believe it's the pattern ^[\| -]\{<\d>,\}[a-zA-Z0-9_]
#     Turns out { and } shouldn't be escaped... I feel like I used to do
#     that a lot... checked tldp again, still says to do that
# - Very first test (for root) is not working, no idea why.
#    This is the test that is failing: [[ root =~ ^\w ]]
#     Bash v4 doesn't do \w apparently, answer is
#     [[ root =~ ^[a-zA-Z0-9_] ]]
# - The names are getting appended to the array with the leading |--
#    Lots of $line in mkdir and appends that should have been $name
# - The second pattern is a more strict version of pattern 1 so pattern
#   1 is matched when I really meant to match pattern 2
#    Fixed this by just reversing the order of the check. Should rename
#    variables too
# - Only works for first layer of depth
#    Forgot to increment magIndent.... slightly important I suppose

# Global variable $magIndent measures indentation level (magnitude) of
# the line.
magIndent=0


# Starting with the main read loop (will need to check for stdin or file)
while read line
do
  # Before we start let's grab just the dirName from the line
  name=`echo $line|cut -d'-' -f3`
#  echo "DEBUG: name = $name"

  # Scratch that, do this for everyone but root
  if [[ -z $name ]]; then
    name=$line
#    echo "DEBUG: name = $name"
  fi

  # test if this is root; make first dir
  if [[ $line =~ ^[a-zA-Z0-9_] ]]; then
    # Need a variable for tracking the last name used in a previous
    # magIndent. Root gets 0, append on each increment.
#    echo "DEBUG: This is root, sweet"
    indentNames=($name)
    mkdir ./$name 2>/dev/null
    magIndent=1
    continue
  fi

  # Test number of indentations
  # Meaning check it matches last indentation
  # and if not then determine the new level.
  
  # Example: root has two subs: croshaw and devian
  # If the next line is an increased indent of 1 then it is a sub of
  # the prev line. If it matches then it is a sub of the prev indent.

  # If it decreases then we'll need a way to determine
  # current indent level and then it should be smooth sailing.
  # To do this we're going to count how many characters exist before
  # the first [a-zA-Z0-9_].

  # Get value of character count for current magIndent (update: awful
  # name choice in retrospect)
  indent=$(($magIndent*3))

  # Get value of incremented indent
  incIndent=$(($indent+3))

  # Turns out the right side of [[ =~ ]] needs to actually be a regex
  # so no variable expansion
  pattern1="^[| -]{${indent},}[a-zA-Z0-9_]"
#  echo "DEBUG: pattern1 = $pattern1"
  pattern2="^[| -]{${incIndent},}[a-zA-Z0-9_]"
#  echo "DEBUG: pattern2 = $pattern2"
 
  # Test for increment
  if [[ $line =~ $pattern2 ]]; then
#    echo "DEBUG: pattern2 is evaluated to true"
    magIndent=$(($magIndent+1))
    path=`echo ${indentNames[@]:0:$magIndent}|tr ' ' '/'`
#    echo "DEBUG: path = $path"
    mkdir ./$path/$name 2>/dev/null
    indentNames[$magIndent]=$name

  # Test for sibling
  # Matches test, so sub of prev indent's name
  elif [[ $line =~ $pattern1 ]]; then
    # mkdir ./<path-to-prev-indent>/$line
    # need to create <path-to-prev-indent>; didn't know you could use
    # a variable in another's interpolation, nifty
#    echo "DEBUG: pattern1 is evaluated to true"
    path=`echo ${indentNames[@]:0:$magIndent}|tr ' ' '/'`
#    echo "DEBUG: path = $path"
    mkdir ./$path/$name 2>/dev/null
    indentNames[${magIndent}]=$name

  # Not so scary, grab number of characters before the first
  # [a-zA-Z0-9_], then divide by 3 for index in array.
  # To do this we'll cut the string in 3 with the delimiter -
  # The answer is the length of the first string + 2
  else
    firstCut=`echo $line|cut -d'-' -f1`
    indent=$((${#firstCut}+2))
    magIndent=$(($indent/3))
    path=`echo ${indentNames[@]:0:$magIndent}|tr ' ' '/'`
#    echo "DEBUG: path = $path"
    mkdir ./$path/$name 2>/dev/null
    indentNames[${magIndent}]=$name
  fi
done < mkDirStruct.template.v2

# DEBUG -- What did we make?
tree ${indentNames[0]}
rm -r ${indentNames[0]}
