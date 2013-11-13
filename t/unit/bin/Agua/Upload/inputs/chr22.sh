-----------------------------168470271111853636581587575442
Content-Disposition: form-data; name="uploadedfiles[]"; filename="chr22.sh"
Content-Type: application/x-shellscript

#!/bin/sh

#BSUB -J chr22
# The name of the job
#BSUB -o /nethome/bioinfo/data/sequence/chromosomes/human/hg19/fasta/chr22-stdout.txt
# print STDOUT to this file
#BSUB -e /nethome/bioinfo/data/sequence/chromosomes/human/hg19/fasta/chr22-stderr.txt
# print STDERR to this file

echo "LS_JOBID: " $LS_JOBID 
echo "LS_JOBPID: " $LS_JOBPID 
echo "LSB_JOBINDEX: " $LSB_JOBINDEX 
echo "LSB_JOBNAME: " $LSB_JOBNAME 
echo "LSB_QUEUE: " $LSB_QUEUE 
echo "LSFUSER: " $LSFUSER 
echo "LSB_JOB_EXECUSER: " $LSB_JOB_EXECUSER 
echo "HOSTNAME: " $HOSTNAME 
echo "LSB_HOSTS: " $LSB_HOSTS 
echo "LSB_ERRORFILE: " $LSB_ERRORFILE 
echo "LSB_JOBFILENAME: " $LSB_JOBFILENAME 
echo "LD_LIBRARY_PATH: " $LD_LIBRARY_PATH cd /nethome/bioinfo/data/sequence/chromosomes/human/hg19/fasta

time /nethome/bioinfo/apps/samtools/0.1.6/samtools faidx chr22.fa cp chr22.fa.fai chr22.fai sed -e 's/(chr[A-Z0-9]*)/.fa/' < chr22.fai > TMP; mv -f TMP chr22.fai -

----------------------------168470271111853636581587575442
Content-Disposition: form-data; name="path"

Project1/Workflow1
-----------------------------168470271111853636581587575442
Content-Disposition: form-data; name="username"

admin
-----------------------------168470271111853636581587575442
Content-Disposition: form-data; name="sessionId"

9999999999.9999.999
-----------------------------168470271111853636581587575442--