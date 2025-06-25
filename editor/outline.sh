##!/bin/bash
clear

inputFile=${1}
action=${2}
indexNo=${3}

if [[ ${#inputFile} = 0 ]] ; then
  echo '■Simple Outliner'
  echo '>help'
  echo '　引数1:対象File'
  echo '　引数2:動作指定'
  echo '　　　　　v...ツリービュー(省略可)'
  echo '　　　　　e...編集'
  echo '　　　　　d...削除'
  echo '　　　　　i...新規ノード挿入'
  echo '　　　　　m...移動'
  echo '　　　　　0～99...対象ノードを編集(eと引数3を省略)'
  echo '　引数3:動作対象ノード番号'
  exit 2
fi

if [[ ! -f $inputFile ]] ; then
  echo "$inputFile なんてファイルないです"
  exit 1
fi

if [[ $action =~ [edim]$ ]] && [[ ${#indexNo} = 0 ]] ; then
  echo '引数3:対象ノード番号を指定して下さい'
  action='v'
fi

if [[ $action =~ ^[0-9]+$ ]] && [[ ${#indexNo} = 0 ]] ; then
  indexNo=$action
  action='e'
fi

if [[ -f ${inputFile} ]] && [[ ${#action} = 0 ]] ; then
  action='v'
fi

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

readarray -t indexlist < <(grep -P '^\.+.+' ${inputFile})
maxCnt="${#indexlist[@]}"

if [[ ${action} == 'v' ]] ; then
  seq $((maxCnt)) | {
    while read -r cnt ; do
      arrycnt=$((cnt-1))
      depth=$(echo "${indexlist[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)

      printf "%03d   " $cnt

      yes '　' | head -n $depth | tr -d '\n'

      case "$depth" in
         '1') printf '📚️'
              ;;
         [2]) printf '└📗'
              ;;
         [34]) printf '└📖'
                 ;;
         [567]) printf '└📄'
                 ;;
         [89]) printf '└🏷️'
                ;;
         '10')  printf '└🗨️'
                ;;        
         *) printf '└🗨️'
            ;;
      esac 

      dots=$(echo "${indexlist[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+')
      title="${indexlist[arrycnt]/$dots/}"
      echo "${title}"
    done
  }

  echo ''
  echo '※引数なしでhelp参照'

  exit 0
fi

if [[ $action =~ [eid]$ ]] ; then
  cp "${inputFile}" "${inputFile}_bk" 
  readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})
  startLine=$(echo "${indexlist[$((indexNo-1))]}" | cut -d: -f 1)
  endLine=$(echo "${indexlist[((indexNo))]}" | cut -d: -f 1)

  
  if [[ $indexNo -le 0 ]] || [[ $indexNo -gt $maxCnt ]] ; then
    echo "$indexNo番目のノードは存在しません"
    exit 5
  fi
  
  if [[ $indexNo -eq 1 ]]; then
    echo '' > tmpFileH
    cat "${inputFile}" | sed -n "1, $((endLine-1))p" > tmpfileB 
    tail -n +$((endLine)) "${inputFile}" > tmpfileF
  fi
  
  if [[ $indexNo -eq $maxCnt ]]; then
    echo 'ketu'
    exit 1
    cat "${inputFile}" | head -n "$((startLine-1))" > tmpfileH
    cat "${inputFile}" | sed -n "$((endLine)), $p" > tmpfileB 
    echo '' > tmpfileF
  fi

  cat "${inputFile}" | head -n "$((startLine-1))" > tmpfileH
  cat "${inputFile}" | sed -n "$((startLine)), $((endLine-1))p" > tmpfileB 
  tail -n +$((endLine)) "${inputFile}" > tmpfileF

  case $action in
    'e')  micro tmpfileB
          wait
          cat tmpfileB >> tmpfileH
          cat tmpfileF >> tmpfileH
          mv  tmpfileH "${inputFile}"
          ;;
    'd')  cat tmpfileF >> tmpfileH
          mv  tmpfileH "${inputFile}"
          ;;

    *)    echo '不正な引数です。'
  esac

fi
