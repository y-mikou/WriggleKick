##!/bin/bash

: "バックアップ関数" && {
  function makeBackup {
    local orgFile="${1}"
    readonly MAX_BACKUP_COUNT=3

    #find ./ -maxdepth 2 -type f | grep -P "$(basename ${orgFile})_bk_[1-${MAX_BACKUP_COUNT}]$"
    
    #3つ以上作る気がない
    if [[ -f "./$(basename ${orgFile})_bk_2" ]] ; then 
      cp "./$(basename ${orgFile})_bk_2" "./$(basename ${orgFile})_bk_3"
    fi
    if [[ -f "./$(basename ${orgFile})_bk_1" ]] ; then 
      cp "./$(basename ${orgFile})_bk_1" "./$(basename ${orgFile})_bk_2"
    fi
    cp "./$(basename ${orgFile})" "./$(basename ${orgFile})_bk_1"
  }
}

: "初期処理" && {
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
    echo '　　　　　t....ツリービュー(省略可)'
    echo '　　　　　v....対象ノードの閲覧'
    echo '　　　　　e....対象ノードの編集'
    echo '　　　　　d....対象ノードの削除'
    echo '　　　　　i....新規ノード挿入'
    echo '　　　　　mu...対象ノードを上へ移動'
    echo '　　　　　md...対象ノードを下へ移動'
    echo '　　　　　ml...対象ノードを左へ移動(浅くする)'
    echo '　　　　　mr...対象ノードを右へ移動(深くする)'
    echo '　　　　　0～99...対象ノードを編集(eと引数3を省略)'
    echo '　引数3:動作対象ノード番号'
    exit 2
  fi

  if [[ ! -f ${inputFile} ]] ; then
    echo "${inputFile} なんてファイルないです"
    read -s -n 1 c
    exit 1
  fi

  if [[ ${action} =~ ^[0-9]+$ ]] && [[ ${#indexNo} = 0 ]] ; then
    indexNo=${action}
    action='e'
  fi

  if [[ ! ${action} =~ [editmv]$ ]] && [[ ! ${action} =~ [ml|mr|mu|md] ]] ; then
      echo '引数2:無効なアクションです'
      read -s -n 1 c
      bash "${0}"
  fi

  if [[ ${action} =~ [edimv]$ ]] && [[ ${#indexNo} = 0 ]] ; then
    echo '引数3:対象ノード番号を指定して下さい'
    read -s -n 1 c
    bash "${0}" "${inputFile}" 't'
    exit 0
  fi

  if [[ ${action} =~ [ml|mr|mu|md] ]] && [[ ${#indexNo} = 0 ]] ; then
    echo '引数3:対象ノード番号を指定して下さい'
    read -s -n 1 c
    bash "${0}" "${inputFile}" 't'
    exit 0
  fi

  if [[ -f ${inputFile} ]] && [[ ${#action} = 0 ]] ; then
    bash "${0}" "${inputFile}" 't'
    exit 0
  fi

  if [[ ${action} =~ [edimv]$ ]] || [[ ${action} =~ [ml|mr|mu|md] ]] ; then
    makeBackup "${inputFile}"
  fi

  : "一時ファイルにかかる処理" && {

    # 一時ファイルを作
    tmpfileH=$(mktemp)
    tmpfileB=$(mktemp)
    tmpfileT=$(mktemp)
    tmpfileF=$(mktemp)
    tmpfile1=$(mktemp)
    tmpfile2=$(mktemp)

    # 生成した一時ファイルを削除する
    function rm_tmpfile {
      [[ -f "${tmpfileH}" ]] && rm -f "${tmpfileH}"
      [[ -f "${tmpfileB}" ]] && rm -f "${tmpfileB}"
      [[ -f "${tmpfileT}" ]] && rm -f "${tmpfileT}"
      [[ -f "${tmpfileF}" ]] && rm -f "${tmpfileF}"
    }
    # 正常終了したとき
    trap rm_tmpfile EXIT
    # 異常終了したとき
    trap 'trap - EXIT; rm_tmpfile; exit -1' INT PIPE TERM

  }
}

: "移動" &&  {
  if [[ ${action:0:1} == 'm' ]] ; then
    #ノードの検出
    readarray -t indexlistN < <(grep -nP '^\.+.+' ${inputFile})
    maxCnt="${#indexlistN[@]}"
    if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
      echo "${indexNo}番目のノードは存在しません"
      read -s -n 1 c
    else
      tgtLine="$(echo ${indexlistN[((indexNo-1))]} | cut -d: -f 1)"
      replaceFrom="$(echo ${indexlistN[((indexNo-1))]} | cut -d: -f 2)"
      depth=$(echo "${replaceFrom}" | grep -oP '^\.+' | grep -o '.' | wc -l)

      direction="${action:1:1}"

      case "${direction}" in
        'l')  if [[ $depth -le 1 ]] ; then
                echo 'それ以上浅くできません'
                read -s -n 1 c
              else
                sed -i -e "$tgtLine s/^\.\./\./g" ${inputFile}
                bash "${0}" "${inputFile}" 't'
                exit 0
              fi
              ;;
        'r')  if [[ $depth -ge 10 ]] ; then
                echo 'それ以上深くできません'
                read -s -n 1 c
              else
                sed -i -e "$tgtLine s/^/\./g" ${inputFile}
                bash "${0}" "${inputFile}" 't'
                exit 0
              fi
              ;;
        'u')  if [[ ${indexNo} -ne 1 ]] ; then
                indexTargetNode="${indexlistN[ $(( ${indexNo} -2 )) ]}"
                indexSelectNode="${indexlistN[ $(( ${indexNo} -1 )) ]}"
                indexNextNode="${indexlistN[   $(( ${indexNo}    )) ]}"

                endlinePreviousNode=$(( $( echo "${indexTargetNode}" | cut -d: -f 1 ) -1 ))
                startlineTargetNode=$(( $( echo "${indexTargetNode}" | cut -d: -f 1 )    ))
                endlineTargetNode=$((   $( echo "${indexSelectNode}" | cut -d: -f 1 ) -1 ))
                startlineSelectNode=$(( $( echo "${indexSelectNode}" | cut -d: -f 1 )    ))
                if [[ ${indexNo} -eq ${maxCnt} ]] ; then
                  endlineSelectNode=$(cat "${inputFile}" | wc -l )
                  startlineNextNode=''
                else
                  endlineSelectNode=$((   $( echo "${indexNextNode}"   | cut -d: -f 1 ) -1 ))
                  startlineNextNode=$((   $( echo "${indexNextNode}"   | cut -d: -f 1 )    ))
                fi
                
                (
                  cat "${inputFile}" | head -n "${endlinePreviousNode}" > "${tmpfileH}"
                  cat "${inputFile}" | sed -sn "${startlineTargetNode},${endlineTargetNode}p" > "${tmpfileT}" 
                  cat "${inputFile}" | sed -sn "${startlineSelectNode},${endlineSelectNode}p" > "${tmpfileB}"
                  if [[ ! ${startlineNextNode} = '' ]] ; then 
                    tail -n +"${startlineNextNode}" "${inputFile}" > "${tmpfileF}"
                  fi
                  wait
                )
                (
                  cat "${tmpfileH}" "${tmpfileB}" > "${tmpfile1}"
                  cat "${tmpfileT}" "${tmpfileF}" > "${tmpfile2}"
                  wait
                )
                cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"
              else
                echo '1番目のノードは上に移動できません。'
                read -s -n 1 c
              fi
              ;;
        'd')  if [[ ${indexNo} -ne ${maxCnt} ]] ; then

                indexPreviousNode="${indexlistN[ $(( ${indexNo} -2 )) ]}"
                indexSelectNode="${indexlistN[   $(( ${indexNo} -1 )) ]}"
                indexTargetNode="${indexlistN[   $(( ${indexNo}    )) ]}"
                indexNextNode="${indexlistN[     $(( ${indexNo} +1 )) ]}"
                endlinePreviousNode=$(( $( echo "${indexSelectNode}" | cut -d: -f 1 ) -1 ))

                startlineSelectNode=$(( $( echo "${indexSelectNode}" | cut -d: -f 1 )    ))
                endlineSelectNode=$((   $( echo "${indexTargetNode}" | cut -d: -f 1 ) -1 ))
                startlineTargetNode=$(( $( echo "${indexTargetNode}" | cut -d: -f 1 )    ))

                if [[ $((${indexNo}+1)) -eq ${maxCnt} ]] ; then
                  endlineTargetNode=$(cat "${inputFile}" | wc -l )
                else
                  endlineTargetNode=$((   $( echo "${indexNextNode}"   | cut -d: -f 1 ) -1 ))
                  startlineNextNode=$((   $( echo "${indexNextNode}"   | cut -d: -f 1 )    ))
                fi

                (
                  cat "${inputFile}" | head -n "${endlinePreviousNode}" > "${tmpfileH}"
                  cat "${inputFile}" | sed -sn "${startlineTargetNode},${endlineTargetNode}p" > "${tmpfileT}" 
                  cat "${inputFile}" | sed -sn "${startlineSelectNode},${endlineSelectNode}p" > "${tmpfileB}"
                  if [[ ! ${startlineNextNode} = '' ]] ; then 
                    tail -n +"${startlineNextNode}" "${inputFile}" > "${tmpfileF}"
                  fi
                  wait
                )
                (
                  cat "${tmpfileH}" "${tmpfileT}" > "${tmpfile1}"
                  cat "${tmpfileB}" "${tmpfileF}" > "${tmpfile2}"
                  wait
                )
                cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"
              else
                echo '最後のノードは下に移動できません。'
                read -s -n 1 c
              fi
              ;;
        *)    echo 'err'
              exit 1
              ;;
      esac
    fi

    bash "${0}" "${inputFile}" 't'
    exit 0

  fi
}

: "グループ移動" &&  {
  if [[ ${action:0:2} == 'gm' ]] ; then

    #ノードの検出
    readarray -t indexlistN < <(grep -nP '^\.+.+' ${inputFile})
    maxCnt="${#indexlistN[@]}"
    if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
      echo "${indexNo}番目のノードは存在しません"
      read -s -n 1 c
    else

      indexSelectNode="${indexlistN[ $(( ${indexNo} -1 )) ]}"
      startlineTargetGroup="$(echo ${indexSelectNode} | cut -d: -f 1)"
      replaceFrom="$(echo ${indexlistN[((indexNo-1))]} | cut -d: -f 2)"
      depth=$(echo "${replaceFrom}" | grep -oP '^\.+' | grep -o '.' | wc -l)

      for i in $(seq $((${indexNo}-1)) $((${maxCnt}-1))) ;
      do
        depthCheck=$(echo "${indexlistN[${i}]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
        if [[ ${depthCheck} -lt ${depth} ]] ; then
          #endlineTargetGroup=$(( $(echo "${indexlistN[${i}]}" | cut -d':' -f 1) - 1 ))
          break
        else
          tgtLine=$(echo "${indexlistN[${i}]}" | cut -d':' -f 1)

          case "${action:2:1}" in
            #グループ単位の深さ移動
            'l')  sed -i -e "$tgtLine s/^\.\./\./g" ${inputFile}
                  ;;
            'r')  sed -i -e "$tgtLine s/^\./\.\./g" ${inputFile}
                  ;;
            *)    echo 'err'
                  read -s -n 1 c
                  break
                  ;;
          esac
        fi
      done

      bash "${0}" "${inputFile}" 't'
      exit 0

    fi
  fi
}

: "挿入" && {
  if [[ ${action} = 'i' ]] ; then
    nlString='New Node'

    readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})
    maxCnt=${#indexlist[@]}

    if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
      echo "${indexNo}番目のノードは存在しません"
      read -s -n 1 c
      bash "${0}" "${inputFile}" 't'
      exit 0
    fi
    
    depth=$(echo "${indexlist[$((indexNo-1))]}" | cut -d: -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)

    firstHalfEndLine=$(($(echo "${indexlist[$((indexNo))]}" | cut -d: -f 1)-1))
    secondHalfStartLine=$(($(echo "${indexlist[$((indexNo))]}" | cut -d: -f 1)))

    dots=$(seq ${depth} | while read -r line; do printf '.'; done)
    echo "${dots}${nlString}" > "${tmpfileB}"
    cat "${inputFile}" | head -n "$((firstHalfEndLine))" > "${tmpfileH}"

    if [[ ${indexNo} -eq ${maxCnt} ]] ;then
      awk 1 "${inputFile}" "${tmpfileB}" > "${tmpfile1}"
      cat "${tmpfile1}" > "${inputFile}"

    else
      cat "${inputFile}" | tail -n +$((secondHalfStartLine))  > "${tmpfileF}"
      cat "${tmpfileH}" "${tmpfileB}" "${tmpfileF}" > "${inputFile}"
    fi

    bash "${0}" "${inputFile}" 't'
    exit 0

  fi
}

: "編集・削除・閲覧" && {
  if [[ ${action} =~ [edv]$ ]] ; then
    
    readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})
    maxCnt="${#indexlist[@]}"
    startLine=$(echo "${indexlist[$((indexNo-1))]}" | cut -d: -f 1)
    endLine=$(echo "${indexlist[((indexNo))]}" | cut -d: -f 1)

    if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
      echo "${indexNo}番目のノードは存在しません"
      read -s -n 1 c
      bash "${0}" "${inputFile}" 't'
      exit 0
    else
      if [[ ${indexNo} -eq 1 ]]; then
        #echo '' > "${tmpfileH}"
        cat "${inputFile}" | sed -n "1, $((endLine-1))p" > "${tmpfileB}"
        tail -n +$((endLine)) "${inputFile}" > "${tmpfileF}"
      else
        if [[ ${indexNo} -eq $maxCnt ]]; then
          cat "${inputFile}" | head -n "$((startLine-1))" > "${tmpfileH}"
          cat "${inputFile}" | tail -n +$((startLine))  > "${tmpfileB}" 
          echo '' > "${tmpfileF}"
        else
          cat "${inputFile}" | head -n "$((startLine-1))" > "${tmpfileH}"
          cat "${inputFile}" | sed -n "$((startLine)), $((endLine-1))p" > "${tmpfileB}" 
          tail -n +$((endLine)) "${inputFile}" > "${tmpfileF}"
        fi
      fi
    fi

    case $action in
      'e')  "${selected_editor}" "${tmpfileB}"
            wait
            sed -i -e '$a\' "${tmpfileB}" #編集の結果末尾に改行がない場合の対応
            cat "${tmpfileH}" "${tmpfileB}" "${tmpfileF}" > "${inputFile}"
            ;;
      'd')  cat "${tmpfileH}" "${tmpfileF}" > "${inputFile}"
            ;;
      'v')  "${selected_viewer}" "${tmpfileB}"
            ;;
      *)    echo '不正な引数です。'
    esac

    bash "${0}" "${inputFile}" 't'
    exit 0

  fi
}

: "ツリー表示" && {
  if [[ "${action}" == 't' ]] ; then
    #ノードの検出
    readarray -t indexlist < <(grep -P '^\.+.+' ${inputFile})
    maxCnt="${#indexlist[@]}"

    seq $((maxCnt)) | {
      while read -r cnt ; do
        arrycnt=$((cnt-1))
        depth=$(echo "${indexlist[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)

        printf "%03d " $cnt
        seq ${depth} | while read -r line; do printf '　'; done
        case "${depth}" in
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

    echo '❓️引数なしでhelp参照'
    exit 0
  fi
}

