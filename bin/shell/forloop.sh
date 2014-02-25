#!/bin/bash

MIN=${1}
MAX=${2}
let MAX=MAX+1
COMMAND=${3}

NUMBER=$MIN

while [ $NUMBER -lt $MAX ];
do
	TEXT=${COMMAND}
	OUT=${TEXT/\$i/$NUMBER}
#	echo "COMMAND $NUMBER: $OUT"
	echo `$OUT`
#	`$OUT` | xargs -L1 -p -iHERE echo HERE
#	echo $RESULT

#	echo $TEXT	
#	echo "Doing $i"
#	mkdir /mnt/inputs/$i
#	cp /teradata/inputs/fastq/HCC1143.mix1.n5t95.fastq /mnt/inputs/$i
#	mkdir /mnt/benchmark/$i

	let NUMBER=NUMBER+1;
done;
