#!/bin/sh
# This is an example shell script showing how your code will
# be graded. It compiles _both_ Assembly programs, but only
# tests ONE of them.  The real grading script will test BOTH.
# You should extend this script to test the decoder as well.
# (Testing is part of the job of writing code.)
# Note that if you pass this script, you will receive at
# least 50% of the points for the Assembler homework!

# Assemble and link encoder
nasm -f elf64 -g -F dwarf base32enc.asm -o b32e.o || { echo "Assembly code base32enc.asm failed to compile"; exit 1; }
ld -o b32e b32e.o || { echo "Object failed to link"; exit 1; }
# Assemble and link decoder
nasm -f elf64 -g -F dwarf base32dec.asm -o b32d.o || { echo "Assembly code base32dec.asm failed to compile"; exit 1; }
ld -o b32d b32d.o || { echo "Object failed to link"; exit 1; }

# run tests
total=0
for n in A OlYx OlYxd OlYxdd33f 7902jf30f8 7902jf30f8ddvv jk394jsfDFasJ33Jdddfc WWWWWWWWWWWWWWWWWWWWWWWWWW
do
  points=1
  timeout -s SIGKILL 1s echo -n $n | ./b32e > tests/$n.out || { echo "Your 'b32' command failed to run: $?" ; points=0 ; }
  echo -n $n | base32 > tests/$n.want || { echo "System 'base32' failed to run"; exit 1; }
  diff -w tests/$n.want tests/$n.out > tests/$n.delta || { echo "Encode failed on $n" ; points=0; }
  if test $points = 1
  then
    echo "Test $n passed"
    total=`expr $total + $points`
  fi
done
# Output grade
echo "Final grade: $total/8"
exit 0
