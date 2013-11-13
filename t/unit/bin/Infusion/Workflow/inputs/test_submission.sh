#! /bin/bash
echo "trying ";  

h=`hostname`; 


date ;



outserver=`grep output_server $1 | awk '{print $2}' `

outdir=`grep output_dir $1 | awk '{print $2}'`

echo $outdir




echo $outdir | sed -e "s/\'//" | xargs mkdir -p 


cp /home/pcruz/src/saffrondev/data/build_stats.txt $outdir





