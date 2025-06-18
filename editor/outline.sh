indexNo=$1
readarray -t indexlist < <(grep -nP '\.+.+' tgt.txt)

startLine=$(echo "${indexlist[indexNo]}" | cut -d: -f 1)
echo $startLine

endLine=$(echo "${indexlist[((indexNo+1))]}" | cut -d: -f 1)
echo $endLine

echo "${indexlist[indexNo]}" | cut -d: -f 2 

