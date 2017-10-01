#!/bin/bash

## Generate a directory structure using a template like the output of
## tree. Would be cool to add Unicode support for piping tree directly
## into this.

## The basics are that there is a root, and each level under root is
## successively indented by three characters, made up of pipes (|) and
## spaces.

## BUGS
# Current working directory needs to be known before we start it seems
#  The name given to mkdir gets a leading slash somehow, ./ in front
#  isn't the most elegant solution but it works.


# Global variable $magIndent measures indentation level (magnitude) of
# the line.
magIndent=0


# Starting with the main read loop (will need to check for stdin or file)
while read line
do
  # Before we start let's grab just the dirName from the line
  name=`echo $line|cut -d'-' -f3`

  # Scratch that, do this for everyone but root
  if [[ -z $name ]]; then
    name=$line
  fi

  # test if this is root; make first dir
  if [[ $line =~ ^\w ]]; then
    # Need a variable for tracking the last name used in a previous
    # magIndent. Root gets 0, append on each increment.
    indentNames=($name)
    mkdir ./$name
    magIndent=1
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
  # the first \w.

  # Get value of character count for current magIndent (update: awful
  # name choice in retrospect)
  indent=$(($magIndent*3))

  # Get value of incremented indent
  incIndent=$(($indent+3))

  # Matches test, so sub of prev indent's name
  # Turns out the right side of [[ =~ ]] needs to actually be a regex
  # so no variable expansion
  pattern1="^[| -]\{${indent},\}\w"
  pattern2="^[| -]\{${incIndent},\}\w"
  if [[ $line =~ $pattern1 ]]; then
    # mkdir ./<path-to-prev-indent>/$line
    # need to create <path-to-prev-indent>; didn't know you could use
    # a variable in another's interpolation, nifty
    path=`echo ${indentNames[@]:0:$magIndent}|tr ' ' '/'`
    echo "DEBUG: path = $path"
    mkdir ./$path/$line
    indentNames[${magIndent}]=$line

  # Doesn't match, test for increment
  elif [[ $line =~ $pattern2 ]]; then
    path=`echo ${indentNames[@]:0:$(($magIndent+1))}|tr ' ' '/'`
    echo "DEBUG: path = $path"
    mkdir ./$path/$line
    indentNames[$(($magIndent+1))]=$line

  # Not so scary, grab number of characters before the first
  # \w, then divide by 3 for index in array.
  # To do this we'll cut the string in 3 with the delimiter -
  # The answer is the length of the first string + 2
  else
    firstCut=`echo $line|cut -d'-' -f1`
    indent=$((${#firstCut}+2))
    magIndent=$(($indent/3))
    path=`echo ${indentNames[@]:0:$magIndent}|tr ' ' '/'`
    echo "DEBUG: path = $path"
    mkdir ./$path/$line
    indentNames[${magIndent}]=$line
  fi

  # DEBUG -- What did we make?
  tree ${indentNames[0]}
done < ~/template
