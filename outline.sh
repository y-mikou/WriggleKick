##!/bin/bash
clear

#エディタの設定
#editorList配列の優先順で存在するコマンドに決定される。
#ユーザによる書き換えも想定
#(selected_editor部分を任意のエディター起動コマンドに変更)
editorList=('selected_editor' 'edit' 'micro' 'nano' 'vi' 'ed')
            #^^^^^^^^^^^^^^^edit here
for itemE in "${editorList[@]}" ; do
  #コマンドがエラーを返すか否かで判断
  \command -v ${itemE} >/dev/null 2>&1
  if [[ $? == 0 ]] ; then
    selected_editor="${itemE}"
    break
  fi
done

#ビューワの設定
#viewerList配列の優先順で存在するコマンドに決定される。
#ユーザによる書き換えも想定
#(selected_viewer部分を任意のビューワ起動コマンドに変更。エディタを設定しても良い)
viewerList=('selected_viewer' 'less' 'more' 'view' 'cat')
            #^^^^^^^^^^^^^^^edit here
for itemV in "${viewerList[@]}" ; do
  #コマンドがエラーを返すか否かで判断
  \command -v ${itemV} >/dev/null 2>&1
  if [[ $? == 0 ]] ; then
    selected_viewer="${itemV}"
    break
  fi
done

inputFile=${1}
action=${2}
indexNo=${3}

if [[ ${#inputFile} = 0 ]] ; then
  echo '■Simple Outliner'
  echo '>help'
  echo '　引数1:対象File'
  echo '　引数2:動作指定'
  echo '　　　　　t...ツリービュー(省略可)'
  echo '　　　　　v...対象ノードの閲覧'
  echo '　　　　　e...対象ノードの編集'
  echo '　　　　　d...対象ノードの削除'
  echo '　　　　　i...新規ノード挿入'
  echo '　　　　　m...対象ノードの移動'
  echo '　　　　　0～99...対象ノードを編集(eと引数3を省略)'
  echo '　引数3:動作対象ノード番号'
  exit 2
fi

if [[ ! -f $inputFile ]] ; then
  echo "$inputFile なんてファイルないです"
  exit 1
fi

if [[ $action =~ [edimv]$ ]] && [[ ${#indexNo} = 0 ]] ; then
  echo '引数3:対象ノード番号を指定して下さい'
  action='t'
fi

if [[ $action =~ ^[0-9]+$ ]] && [[ ${#indexNo} = 0 ]] ; then
  indexNo=$action
  action='e'
fi

if [[ -f ${inputFile} ]] && [[ ${#action} = 0 ]] ; then
  action='t'
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

#ノードの検出
readarray -t indexlist < <(grep -P '^\.+.+' ${inputFile})
maxCnt="${#indexlist[@]}"

if [[ ${action} == 't' ]] ; then
  seq $((maxCnt)) | {
    while read -r cnt ; do
      arrycnt=$((cnt-1))
      depth=$(echo "${indexlist[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)

      printf "%03d " $cnt
      seq $depth | while read -r line; do printf '　'; done
      case "$depth" in
         '1') printf '📚️ '
              ;;
         [2]) printf '└📗 '
              ;;
         [34]) printf '└📖 '
                 ;;
         [567]) printf '└📄 '
                 ;;
         [89]) printf '└🏷️ '
                ;;
         '10')  printf '└🗨️ '
                ;;        
         *) printf '└🗨️ '
            ;;
      esac 

      #表示時にはノードを示す'.'を消す
      dots=$(echo "${indexlist[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+')
      title="${indexlist[arrycnt]#$dots}"
      echo "${title}"
    done
  }

  echo ''
  echo '❓️引数なしでhelp参照'

  exit 0
fi

if [[ $action =~ [eidv]$ ]] ; then
  cp "${inputFile}" "${inputFile}_bk" 
  readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})
  startLine=$(echo "${indexlist[$((indexNo-1))]}" | cut -d: -f 1)
  endLine=$(echo "${indexlist[((indexNo))]}" | cut -d: -f 1)

  
  if [[ $indexNo -le 0 ]] || [[ $indexNo -gt $maxCnt ]] ; then
    echo "$indexNo番目のノードは存在しません"
    exit 5
  else
    if [[ $indexNo -eq 1 ]]; then
      echo '' > tmpFileH
      cat "${inputFile}" | sed -n "1, $((endLine-1))p" > tmpfileB 
      tail -n +$((endLine)) "${inputFile}" > tmpfileF
    else
      if [[ $indexNo -eq $maxCnt ]]; then
        cat "${inputFile}" | head -n "$((startLine-1))" > tmpfileH
        cat "${inputFile}" | tail -n +$((startLine))  > tmpfileB 
        echo '' > tmpfileF
      else
        cat "${inputFile}" | head -n "$((startLine-1))" > tmpfileH
        cat "${inputFile}" | sed -n "$((startLine)), $((endLine-1))p" > tmpfileB 
        tail -n +$((endLine)) "${inputFile}" > tmpfileF
      fi
    fi
  fi

  case $action in
    'e')  ${selected_editor} tmpfileB
          wait
          cat tmpfileB >> tmpfileH
          cat tmpfileF >> tmpfileH
          mv  tmpfileH "${inputFile}"
          ;;
    'd')  cat tmpfileF >> tmpfileH
          mv  tmpfileH "${inputFile}"
          ;;
    'v')  ${selected_viewer} tmpfileB
          ;;

    *)    echo '不正な引数です。'
  esac

fi
