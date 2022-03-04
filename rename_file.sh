#! /bin/sh
i = 0
for eachfile in `ls -B $1 | grep *.md`
do
  echo ${eachfile}
  #filename=${eachfile%.txt}
  #mv $filename.txt ${filelast}_$filehead.txt
done
