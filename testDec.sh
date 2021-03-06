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

echo "-----Decoding from Base32 Tests------"
# run tests
total=0
for n in IE====== IFAQ==== IFBEGRCF IFBEGRCFIZDQ==== ONTGUZCEIR3DGNDGMZLVOV3G ONTGUZCEIR3DGNDGMZLVOV3GMRSHM5TBOFZXGMTW GM2EM2TLNRWWIZCBIFAWCYLBME====== NRSG2OCEHEYDINDSIZDEM5TWMFQWGY2EGJVGWZT2OVUWYZTEONQXGZDWONUXK43ENBTGM43ONFSHGZTOMZZWMZDTMZVHGZDLMZZWI23EONTHGZDLNJTGI43TMRVWM23ENZTGW43EMZVXGZDGNRSHGZTOMRTGY43LMRTHG23EONSGY23KNNZWI2TGNRVWI43KMZZWWZDGNI======
do
  points=1
  timeout -s SIGKILL 1s echo -n $n | ./b32d > tests/$n.out || { echo "Your 'b32' command failed to run: $?" ; points=0 ; }
  echo -n $n | base32 -d > tests/$n.want || { echo "System 'base32' failed to run"; exit 1; }
  diff -w tests/$n.want tests/$n.out > tests/$n.delta || { echo "Decode failed on $n" ; points=0; }
  if test $points = 1
  then
    echo "Test $n passed"
    total=`expr $total + $points`
  fi
done
# Output grade
echo "Final grade: $total/8"
echo "------------------------------------"
exit 0
