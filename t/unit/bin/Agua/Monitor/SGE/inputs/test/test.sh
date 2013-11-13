#!/bin/sh                                                                                                       
#BSUB -J test1
#BSUB -o %J.out
#BSUB -e %J.err
#BSUB -W 1:00
#BSUB -q priority
#BSUB -n 1
##BSUB -B
##BSUB -N                                                                                              

echo "Running serial executable on 1 cpu of one node"
# Run serial executable on 1 cpu of one node                                                                    
/usr/bin/perl $INSTALLDIR/t/cgi-bin/jobs/test/test.pl $LSB_JOBID b c

exit;
####
