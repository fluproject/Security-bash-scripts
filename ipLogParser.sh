#!/bin/bash

#***************************************************
#	$ ./ipLogParser.sh <path> <ip>
#***************************************************

i=0
patron=$2
typeset ARRAY[10]
for file in $(find $1 -type "f")
do
    i=$(($i+1));
    l=0
    while read line
    do
        pos=$(($l%10));
        ARRAY[$pos]=$line
        case $line in
            *"$patron"*) 
                posip=$(($l-8));
                pos=$(($posip % 10));
                ip=${ARRAY[$pos]}
                #Next, you can indicate an IP addresses to ignore
                if [[ $ip != *"8.8.8.8"* ]]
                then 
                    echo -e "**********************\nFile: $file\nLine: $l\nIP: $ip\nLog: $line\n**********************\n";
                fi
        esac
        l=$(($l+1));
    done < "$file"
done
echo "Files analyzed: $i";
