inputFile=${1}
indexNo=${2}

cp "${inputFile}" "${inputFile}_bk" 

# 一時ファイルを作る
tmpfileH=$(mktemp)
tmpfileB=$(mktemp)
tmpfileF=$(mktemp)

# 生成した一時ファイルを削除する
function rm_tmpfile {
  [[ -f "$tmpfile" ]] && rm -f "$tmpfile"
}
# 正常終了したとき
trap rm_tmpfile EXIT
# 異常終了したとき
trap 'trap - EXIT; rm_tmpfile; exit -1' INT PIPE TERM

readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})

if [[ ${indexNo} == 'v' ]] ; then
  maxCnt="${#indexlist[@]}"
  seq $((maxCnt-1)) | { 
    while read -r cnt && [ $cnt ] ; do
      depth=$(echo "${indexlist[cnt]}" | cut -d: -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
      echo $depth
    
      #echo "$cnt---${indexlist[cnt]}"
    done
  }
  exit 0
fi

startLine=$(echo "${indexlist[indexNo]}" | cut -d: -f 1)
endLine=$(echo "${indexlist[((indexNo+1))]}" | cut -d: -f 1)

head -n $((startLine-1)) "${inputFile}" > tmpfileH
tail -n +$((endLine)) "${inputFile}" > tmpfileF
cat "${inputFile}" | sed -n "$((startLine)), $((endLine-1))p" > tmpfileB 

micro tmpfileB
wait

cat tmpfileB >> tmpfileH
cat tmpfileF >> tmpfileH
mv  tmpfileH "${inputFile}"
