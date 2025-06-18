inputFile=${1}
indexNo=${2}

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
#trap 'trap - EXIT; rm_tmpfile; exit -1' INT PIPE TERM

readarray -t indexlist < <(grep -nP '\.+.+' ${inputFile})

startLine=$(echo "${indexlist[indexNo]}" | cut -d: -f 1)
endLine=$(echo "${indexlist[((indexNo+1))]}" | cut -d: -f 1)


head -n $((startLine-1)) "${inputFile}" > tmpfileH &
tail -n +$((endLine)) "${inputFile}" > tmpfileF &
cat "${inputFile}" | sed -n "$((startLine)), $((endLine-1))p" > tmpfileB 

edit tmpfileB

echo "owari"
