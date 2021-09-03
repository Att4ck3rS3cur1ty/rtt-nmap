#!/bin/bash

# Reads the host's input file and saves the RTT results to file 
input=$1

# it will try to remove the files and will suppress any error message if it doesn't exist
rm -f -- temp_rtt rtt_average output_average

# creates the required files 
touch temp_rtt rtt_average output_average

while IFS= read -r line
do
    # pings "-c" times and stores the lines starting with rtt only
    ping -c 10 $line | awk '/rtt/' | cut -d "=" -f 2 >> temp_rtt
done < $input

# reads the RTT results file, captures rtt_avg only and prints it
while IFS= read -r line
do
    slash=0
    rtt_temp=$line

    for i in $(seq 1 ${#rtt_temp}); do
        # checks if the current char is a /
        if [ "${rtt_temp:i-1:1}" == "/" ]
        then
            ((slash++))
            if [ $slash -eq 1 ]
            then
                # captures the value between the first and the second slash
                rtt_avg=$(echo ${rtt_temp:i} | cut -d "/" -f1)
                echo "$rtt_avg" >> rtt_average
            fi
        fi 
    done
done < "temp_rtt"

# concatenate the hosts to its rtt average
paste -d ':' $input rtt_average > output_average

while IFS= read -r line
do
    echo "$line"
done < "output_average"

sum_avg=$(paste -sd+ rtt_average | bc)
num_hosts=$(cat $input | wc -l)
final_avg=$(echo "scale=1; $sum_avg / $num_hosts" | bc)
rtt_initial=$(echo "scale=1; $final_avg * 2"  | bc)
rtt_max=$(echo "scale=1; $final_avg * 3"  | bc)

echo ""
echo "Sum of all RTT average values: $sum_avg ms"
echo ""
echo "Number of hosts: $num_hosts"
echo ""
echo "Final average (average of all host's RTT average): $final_avg ms"
echo ""
echo "Set the --initial-rtt-timeout to: $rtt_initial ms"
echo ""
echo "Set the --max-rtt-timeout to: $rtt_max ms"

# deletes the temp_rtt and rtt_average files, which are no longer necessary
rm -f -- temp_rtt rtt_average output_average
