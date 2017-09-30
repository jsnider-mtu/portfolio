#!/bin/bash

## Generate a directory structure using a template like the output of
## tree. Would be cool to add Unicode support for piping tree directly
## into this.

## The basics are that there is a root, and each level under root is
## successively indented by three characters, made up of pipes (|) and
## spaces.

# Global variable $magIndent measures indentation level (magnitude) of
# the line.
magIndent=0


# Starting with the main read loop (will need to check for stdin or file)
while read line
do
  # test if this is root; make first dir
  if [[ $line =~ ^\w ]]; then
    # Need a variable for tracking the last name used in a previous
    # magIndent. Root gets 0, append on each increment.
    indentNames=($line)
    mkdir $line
    magIndent=1
  fi

  # Test number of indentations
  # Meaning check it matches last indentation
  # and if not then determine the new level.
  
  # Example: root has two subs: croshaw and devian
  # If the next line is an increased indent of 1 then it is a sub of
  # the prev line. If it matches then it is a sub of the prev indent.

  # If it decreases then sacrifice the lamb and spread the blood
  # evenly for now.

  # Get value of character count for current magIndent
  indent=$(($magIndent * 3))

  # Get value of incremented indent
  incIndent=$(($indent+3))

  # Matches test, so sub of prev indent's name
  if [[ $line =~ ^[| -]\{${indent},\}\w ]]; then
    # mkdir <path-to-prev-indent>/$line
    # need to create <path-to-prev-indent>; didn't know you could use
    # a variable in another's interpolation, nifty
    path=`echo ${indentNames[@]:0:$indent}|tr ' ' '/'`
    mkdir $path/$line
    indentNames[${incIndent}]=$line

  # Doesn't match, test for increment
  elif [[ $line =~ ^[| -]\{${incIndent},\}\w ]]; then
    path=`echo ${indentNames[@]:0:$incIndent}|tr ' ' '/'`
    mkdir $path/$line
    indentNames[$(($incIndent+1))]=$line

  # Shit, it's a decrement of some sort; get the lamb
  else

  fi
done < myTemplate
