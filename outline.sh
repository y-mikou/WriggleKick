##!/bin/bash

: "ノード検出" && {
  ##############################################################################
  # ノード検出
  # 入力ファイルのノード構成を検出する
  # 引数1:対象ファイルパス
  # 引数2:'mu'
  # 引数3:対象ノード番号
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function detectNode {
    
    readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})

    maxCnt="${#indexlist[@]}"
    tgtLine="$(echo ${indexlist[((indexNo-1))]} | cut -d: -f 1)"
    replaceFrom="$(echo ${indexlist[((indexNo-1))]} | cut -d: -f 2)"
    depth=$(echo "${replaceFrom}" | grep -oP '^\.+' | grep -o '.' | wc -l)
  
  }
}

: "ツリー表示コマンド" && {
  ##############################################################################
  # ツリー表示する
  # t:通常ツリー
  # tl:行番号付きツリー
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function displayTree {

    #ノードの検出
    detectNode

    echo "【$(basename ${inputFile})】"
    if [[ "${action}" == 'tl' ]] ; then 
      echo 'ノード 行番号    アウトライン'
      echo '------+--------+------------'
    else
      echo 'ノード  アウトライン'
      echo '------+------------'
    fi

    seq $((maxCnt)) | {
      while read -r cnt ; do
        arrycnt=$((cnt-1))
        line=$(echo "${indexlist[arrycnt]}" | cut -d: -f 1)
        depth=$(echo "${indexlist[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)

        printf "%06d" "${cnt}"
        if [[ "${action}" == 'tl' ]] ; then 
          printf " %08d" "${line}"
        fi
        seq ${depth} | while read -r line; do printf '  '; done
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
        dots=$(echo "${indexlist[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+' )
        title=$(echo "${indexlist[arrycnt]}" | cut -d: -f 2)
        title="${title#$dots}"
        echo "${title}"
      done
    }

    echo '❓️引数なしでhelp参照'
    exit 0
  }
}

: "フォーカスモードコマンド" && {
  ##############################################################################
  # 対象グループをフォーカス表示する
  # f:通常フォーカス表示
  # fl:行番号付きフォーカス表示
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function focusMode {
    #ノードの検出   

    readarray -t indexlistN < <(grep -nP '^\.+.+' ${inputFile})

    maxCnt="${#indexlistN[@]}"
    if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
      echo "${indexNo}番目のノードは存在しません"
      read -s -n 1 c
    fi
    
    startnodeSelectGroup="$(( ${indexNo} ))"
    replaceFrom="$(echo ${indexlistN[((indexNo-1))]} | cut -d: -f 2)"
    depth=$(echo "${replaceFrom}" | grep -oP '^\.+' | grep -o '.' | wc -l)

    for i in $(seq $((${indexNo})) $((${maxCnt}))) ;
    do
      depthCheck=$(echo "${indexlistN[${i}]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
      if [[ ${depthCheck} -le ${depth} ]] ; then
        endnodeSelectGroup=$((${i}))
        break
      fi
    done

    if [[ ${endnodeSelectGroup} -le 0 ]] ; then
      endnodeSelectGroup="${maxCnt}"
    fi

    echo "【$(basename ${inputFile})】★フォーカス表示中"
    if [[ "${action}" == 'fl' ]] ; then 
      echo 'ノード 行番号    アウトライン'
      echo '------+--------+------------'
    else
      echo 'ノード  アウトライン'
      echo '------+------------'
    fi

    seq ${startnodeSelectGroup} ${endnodeSelectGroup} | {
      while read -r cnt ; do
      arrycnt=$((cnt-1))
      line=$(echo "${indexlistN[arrycnt]}" | cut -d: -f 1)
      depth=$(echo "${indexlistN[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)

      printf "%06d" "${cnt}"
      if [[ "${action}" == 'fl' ]] ; then 
        printf " %08d" "${line}"
      fi
      seq ${depth} | while read -r line; do printf '  '; done
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
        dots=$(echo "${indexlistN[arrycnt]}" | cut -d: -f 2 | grep -oP '^\.+' )
        title=$(echo "${indexlistN[arrycnt]}" | cut -d: -f 2)
        title="${title#$dots}"
        echo "${title}"
      done
    }

    echo '❓️引数なしでhelp参照'
    exit 0
   
  }
}


: "単ノード移動コマンド" && {
  ##############################################################################
  # 対象のノード一つだけを移動する(指定の方向のノードと入れ替える)
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function moveNode {

    direction="${char2}"

    case "${direction}" in
      'l')  if [[ $depth -le 1 ]] ; then
              echo 'それ以上浅くできません'
              read -s -n 1 c
            else
              sed -i -e "$tgtLine s/^\.\./\./g" ${inputFile}
            fi
            ;;
      'r')  if [[ $depth -ge 10 ]] ; then
              echo 'それ以上深くできません'
              read -s -n 1 c
            else
              sed -i -e "$tgtLine s/^/\./g" ${inputFile}
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
                cat "${inputFile}" | { head -n "${endlinePreviousNode}" > "${tmpfileH}"; cat >/dev/null;}
                cat "${inputFile}" | { sed -sn "${startlineTargetNode},${endlineTargetNode}p" > "${tmpfileT}"; cat >/dev/null;}
                cat "${inputFile}" | { sed -sn "${startlineSelectNode},${endlineSelectNode}p" > "${tmpfileB}"; cat >/dev/null;}
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
                cat "${inputFile}" | { head -n "${endlinePreviousNode}" > "${tmpfileH}"; cat >/dev/null;}
                cat "${inputFile}" | { sed -sn "${startlineTargetNode},${endlineTargetNode}p" > "${tmpfileT}"; cat >/dev/null;} 
                cat "${inputFile}" | { sed -sn "${startlineSelectNode},${endlineSelectNode}p" > "${tmpfileB}"; cat >/dev/null;}
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

    bash "${0}" "${inputFile}" 't'
    exit 0

  }

}

: "バックアップ関数" && {
  ##############################################################################
  # バックアップ作成
  # 引数1:バックアップ対象ファイルパス
  # 引数2:世代数
  ##############################################################################
  function makeBackup {
    local orgFile="${1}"
    local MAX_BACKUP_COUNT=${2}
  
    #3つ以上作る気がない
    #echo 'バックアップ作成'
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
  ##############################################################################
  # 初期処理
  ##############################################################################
  function myInit {
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

    ################################################
    # 動作指定の読み替え
    ################################################

    #(存在する)ファイルのみを指定した場合、ツリービューに読み替え
    if [[ ${#action} = 0 ]] ; then
      bash "${0}" "${inputFile}" 't'
      return 0
    fi

    #動作指定を省略して段落を指定した場合、編集に読み替え
    if [[ ${action} =~ ^[0-9]+$ ]] && [[ ${#indexNo} = 0 ]] ; then
      bash "${0}" "${inputFile}" 'e' "${action}"
      return 0
    fi

    needNodeActionList=('e' 'd' 'i' 'f' 'fl' 'v' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd')
    printf '%s\n' "${needNodeActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] ; then
      if [[ ${#indexNo} = 0 ]] ; then
        echo '引数3:対象ノード番号を指定して下さい'
        read -s -n 1 c
        bash "${0}" "${inputFile}" 't'
        return 0
      fi
    fi

    if [[ -f ${inputFile} ]] && [[ ${#action} = 0 ]] ; then
      bash "${0}" "${inputFile}" 't'
      return 0
    fi

    makeBackupActionList=('e' 'd' 'i' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd')
    printf '%s\n' "${makeBackupActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] ; then
      makeBackup "${inputFile}"
    fi
  }
}

: "パラメーターチェック" && {
  ##############################################################################
  # 引数1:対象ファイルパス
  # 引数2:動作区分
  # 引数3:対象ノード番号
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function parameterCheck {
 
    #対象ファイルの存在チェック
    if [[ ! -f ${inputFile} ]] ; then
      echo "${inputFile} なんてファイルないです"
      read -s -n 1 c
      return 1
    fi

    #動作指定のチェック
    allowActionList=('h' 'e' 'd' 'i' 't' 'tl' 'f' 'fl' 'v' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -ne 0 ]] ; then
      echo '引数2:無効なアクションです'
      read -s -n 1 c
      return 1
    fi

    needTgtActionList=('e' 'd' 'i' 'f' 'fl' 'v' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd')
    printf '%s\n' "${needTgtActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] ; then
      detectNode
      if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
        echo "${indexNo}番目のノードは存在しません"
        read -s -n 1 c
        return 1
      fi
    fi
  }
}

: "一時ファイルにかかる処理" && {
  ##############################################################################
  # 一時ファイル削除
  # 引数:なし
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function rm_tmpfile {
    [[ -f "${tmpfileH}" ]] && rm -f "${tmpfileH}"
    [[ -f "${tmpfileB}" ]] && rm -f "${tmpfileB}"
    [[ -f "${tmpfileT}" ]] && rm -f "${tmpfileT}"
    [[ -f "${tmpfileF}" ]] && rm -f "${tmpfileF}"
  }

  ##############################################################################
  # 一時ファイル作成
  # 引数:なし
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function makeTmpfile {

    # 一時ファイルを作る
    tmpfileH=$(mktemp)
    tmpfileB=$(mktemp)
    tmpfileT=$(mktemp)
    tmpfileF=$(mktemp)
    tmpfile1=$(mktemp)
    tmpfile2=$(mktemp)

  }
}

: "HELP表示" && {
  ##############################################################################
  # 引数:なし
  ##############################################################################
  function displayHelp {
    echo '■Simple Outliner'
    echo '>help'
    echo '　引数1:対象File'
    echo '　引数2:動作指定'
    echo '　　　　　t.....ツリービュー(省略可)'
    echo '　　　　　tl....行番号付きツリービュー'
    echo '　　　　　f.....フォーカスビュー'
    echo '　　　　　fl....行番号付きフォーカスビュー'
    echo '　　　　　v.....対象ノードの閲覧'
    echo '　　　　　e.....対象ノードの編集'
    echo '　　　　　d.....対象ノードの削除'
    echo '　　　　　i.....対象ノードの下に新規ノード挿入'
    echo '　　　　　mu....対象ノードひとつを上へ移動'
    echo '　　　　　md....対象ノードひとつを下へ移動'
    echo '　　　　　ml....対象ノードひとつを左へ移動(浅くする)'
    echo '　　　　　mr....対象ノードひとつを右へ移動(深くする)'
    echo '　　　　　gmu...自分の配下ノードを引き連れて上へ移動'
    echo '　　　　　gmd...自分の配下ノードを引き連れて下へ移動'
    echo '　　　　　gml...自分の配下ノードを引き連れて左へ移動(浅くする)'
    echo '　　　　　gmr...自分の配下ノードを引き連れて右へ移動(深くする)'
    echo '　　　　　0～99...対象ノードを編集(eと引数3を省略)'
    echo '　引数3:動作対象ノード番号'
  }
}

: "主処理" && {
  ##############################################################################
  # 主処理
  # 引数1:対象ファイルパス
  # 引数2:動作区分
  # 引数3:対象ノード番号
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function main {
    
    inputFile="${1}"
    action="${2}"
    indexNo=${3}

    #パラメータチェック
    parameterCheck
    if [[ ${?} != 0 ]] ; then 
      exit 1
    fi

    myInit                      # 初期処理
    makeBackup "${inputFile}" 3 # バックアップ作成。今のところ3世代固定
    makeTmpfile                 # 一時ファイルを作成
    #displayHelp                 # ヘルプ表示

    char1="${action:0:1}"
    char2="${action:1:1}"

    case "${char1}" in
      'h')  displayHelp
            ;;
      't')  displayTree
            ;;
      'm')  moveNode
            ;;
      'f')  focusMode
            ;;
      *) ;;
    esac
  }  
}

###########################################
# エントリーポイント
###########################################

main "${1}" "${2}" "${3}"

# 正常終了したときに一時ファイルを削除する
trap rm_tmpfile EXIT
# 異常終了したときに一時ファイルを削除する
trap 'trap - EXIT; rm_tmpfile; exit -1' INT PIPE TERM
 

# : "グループ移動" &&  {
#   if [[ ${action:0:2} == 'gm' ]] ; then

#     #ノードの検出   
#     readarray -t indexlistN < <(grep -nP '^\.+.+' ${inputFile})
#     maxCnt="${#indexlistN[@]}"
    
#     if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
#       echo "${indexNo}番目のノードは存在しません"
#       read -s -n 1 c
#     else

#       startnodeSelectGroup="$(( ${indexNo} - 1 ))"
#       replaceFrom="$(echo ${indexlistN[((indexNo-1))]} | cut -d: -f 2)"
#       depth=$(echo "${replaceFrom}" | grep -oP '^\.+' | grep -o '.' | wc -l)

#       for i in $(seq $((${indexNo})) $((${maxCnt}))) ;
#       do
#         depthCheck=$(echo "${indexlistN[${i}]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
#         if [[ ${depthCheck} -le ${depth} ]] ; then
#           endnodeSelectGroup=$((${i}))
#           break
#         fi
#       done

#       startlineSelectGroup=$(echo "${indexlistN[ ${startnodeSelectGroup} ]}" | cut -d':' -f 1)
#       if [[ ${endnodeSelectGroup} -ne ${maxCnt} ]] ; then
#         endlineSelectGroup=$(( $(echo "${indexlistN[ ${endnodeSelectGroup} ]}" | cut -d':' -f 1) - 1 ))
#       else
#         endlineSelectGroup=$(cat ${inputFile} | wc -l)
#       fi
#       # echo "${startlineSelectGroup}-${endlineSelectGroup}"

#       case "${action:2:1}" in
#         #グループ単位の深さ移動
#         'l')  for i in $(seq ${startnodeSelectGroup} ${endnodeSelectGroup}) ;
#               do
#                 tgtLine=$(echo "${indexlistN[$i]}" | cut -d: -f 1)
#                 sed -i -e "${tgtLine} s/^\.\./\./g" ${inputFile}
#               done
#               ;;
#         'r')  for i in $(seq ${startnodeSelectGroup} ${endnodeSelectGroup}) ;
#               do
#                 tgtLine=$(echo "${indexlistN[$i]}" | cut -d: -f 1)
#                 sed -i -e "${tgtLine} s/^\./\.\./g" ${inputFile}
#               done
#               ;;
#         'u')  indexCheck=$(( ${indexNo} - 2 ))
#               depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
#               i=2
#               while [[ ${depth} -ne ${depthCheck} ]] && [[ ${indexCheck} -gt 0 ]] ;
#               do
#                 indexCheck=$(( ${indexNo} - ${i} ))
#                 depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
#                 i=$(($i+1))
#               done
#               if [[ ${indexCheck} -eq  0 ]] ; then
#                 echo '移動可能なノードがありません'
#                 read -s -n 1 c
#                 bash "${0}" "${inputFile}" 't'
#                 exit 0
#               fi

#               startlineTargetGroup=$(echo "${indexlistN[ ${indexCheck} ]}"| cut -d':' -f 1)
#               endlineTargetGroup=$(echo $(( $( echo "${indexlistN[ $((${indexNo}-1)) ]}"| cut -d':' -f 1 ) - 1 ))) 

#               startlineHeadGroup='1'
#               endlineHeadGroup=$(( ${startlineTargetGroup} - 1 ))

#               if [[ ${endnodeSelectGroup} -ne ${maxCnt} ]] ; then
#                 startlineFooterGroup=$(( ${endlineSelectGroup} + 1))
#                 endlineFooterGroup=$( cat "${inputFile}" | wc -l  )
#               fi

#               echo "${startlineHeadGroup}-${endlineHeadGroup}"
#               echo "${startlineTargetGroup}-${endlineTargetGroup}"
#               echo "${startlineSelectGroup}-${endlineSelectGroup}"
#               echo "${startlineFooterGroup}-${endlineFooterGroup}"
# exit 1

#               (
#                 cat "${inputFile}" | { head -n "${endlineHeadGroup}" > "${tmpfileH}"; cat >/dev/null;}
#                 cat "${inputFile}" | { sed -sn "${startlineSelectGroup},${endlineSelectGroup}p" > "${tmpfileT}"; cat >/dev/null;} 
#                 cat "${inputFile}" | { sed -sn "${startlineTargetGroup},${endlineTargetGroup}p" > "${tmpfileB}"; cat >/dev/null;}

#                 if [[ ${endnodeSelectGroup} -ne ${maxCnt} ]] ; then
#                   tail -n +"${startlineFooterGroup}" "${inputFile}" > "${tmpfileF}"
#                 fi
#                 wait
#               )
#               (
#                 cat "${tmpfileH}" "${tmpfileT}" > "${tmpfile1}"
#                 if [[ ${endnodeSelectGroup} -ne ${maxCnt} ]] ; then
#                   cat "${tmpfileB}" "${tmpfileF}" > "${tmpfile2}"
#                 else
#                   cat "${tmpfileB}" > "${tmpfile2}"
#                 fi
#                 wait
#               )
#               cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"
        
#               ;;
#         'd')  indexCheck=$(( ${indexNo} + 1 ))
#               depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
#               i=0
#               while [[ ${depth} -ne ${depthCheck} ]] && [[ ${indexCheck} -gt 0 ]] ;
#               do
#                 i=$(($i+1))
#                 indexCheck=$(( ${indexNo} + ${i} ))
#                 depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
#               done
#               if [[ ${indexCheck} -eq  0 ]] ; then
#                 echo '移動可能なノードがありません'
#                 read -s -n 1 c
#                 bash "${0}" "${inputFile}" 't'
#                 exit 0
#               fi
#               indexCheck=$(($i+indexCheck))

#               i=0
#               while [[ ${depth} -ne ${depthCheck} ]] && [[ ${indexCheck} -gt 0 ]] ;
#               do
#                 i=$(($i+1))
#                 indexCheck=$(( ${indexNo} + ${i} ))
#                 depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
#               done


#               startlineTargetGroup=$(echo "${indexlistN[ $((${indexCheck})) ]}"| cut -d':' -f 1)
#               endlineTargetGroup=$(echo $(( $( echo "${indexlistN[ $((${indexCheck} + 1 )) ]}"| cut -d':' -f 1 ) - 1 )))


#               startlineHeadGroup='1'
#               endlineHeadGroup=$(( ${startlineSelectGroup} - 1 ))

#               startlineFooterGroup=$(( ${endlineTargetGroup} + 1))
#               endlineFooterGroup=$( cat "${inputFile}" | wc -l  )

#               echo "${startlineHeadGroup}-${endlineHeadGroup}"
#               echo "${startlineSelectGroup}-${endlineSelectGroup}"
#               echo "${startlineTargetGroup}-${endlineTargetGroup}"
#               echo "${startlineFooterGroup}-${endlineFooterGroup}"
# exit 1
#               (
#                 cat "${inputFile}" | { head -n "${endlineHeadGroup}" > "${tmpfileH}"; cat >/dev/null;}
#                 cat "${inputFile}" | { sed -sn "${startlineTargetGroup},${endlineTargetGroup}p" > "${tmpfileT}"; cat >/dev/null;} 
#                 cat "${inputFile}" | { sed -sn "${startlineSelectGroup},${endlineSelectGroup}p" > "${tmpfileB}"; cat >/dev/null;}
#                 tail -n +"${startlineFooterGroup}" "${inputFile}" > "${tmpfileF}"
#                 wait
#               )
#               (
#                 cat "${tmpfileH}" "${tmpfileT}" > "${tmpfile1}"
#                 cat "${tmpfileB}" "${tmpfileF}" > "${tmpfile2}"
#                 wait
#               )
#               cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"
#               ;;
#         *)    echo 'err'
#               read -s -n 1 c
#               ;;
#       esac

#       bash "${0}" "${inputFile}" 't'
#       exit 0
#     fi
#   fi
# }

# : "挿入" && {
#   if [[ ${action} = 'i' ]] ; then
#     nlString='New Node'

#     readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})
#     maxCnt=${#indexlist[@]}

#     if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
#       echo "${indexNo}番目のノードは存在しません"
#       read -s -n 1 c
#       bash "${0}" "${inputFile}" 't'
#       exit 0
#     fi
    
#     depth=$(echo "${indexlist[$((indexNo-1))]}" | cut -d: -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)

#     firstHalfEndLine=$(($(echo "${indexlist[$((indexNo))]}" | cut -d: -f 1)-1))
#     secondHalfStartLine=$(($(echo "${indexlist[$((indexNo))]}" | cut -d: -f 1)))

#     dots=$(seq ${depth} | while read -r line; do printf '.'; done)
#     echo "${dots}${nlString}" > "${tmpfileB}"
#     cat "${inputFile}" | { head -n "$((firstHalfEndLine))" > "${tmpfileH}"; cat >/dev/null;}

#     if [[ ${indexNo} -eq ${maxCnt} ]] ;then
#       awk 1 "${inputFile}" "${tmpfileB}" > "${tmpfile1}"
#       cat "${tmpfile1}" > "${inputFile}"

#     else
#       cat "${inputFile}" | { tail -n +$((secondHalfStartLine))  > "${tmpfileF}"; cat >/dev/null;}
#       cat "${tmpfileH}" "${tmpfileB}" "${tmpfileF}" > "${inputFile}"
#     fi

#     bash "${0}" "${inputFile}" 't'
#     exit 0

#   fi
# }

# : "編集・削除・閲覧" && {
#   if [[ ${action} =~ [edv]$ ]] ; then
    
#     readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})
#     maxCnt="${#indexlist[@]}"
#     startLine=$(echo "${indexlist[$((indexNo-1))]}" | cut -d: -f 1)
#     endLine=$(echo "${indexlist[((indexNo))]}" | cut -d: -f 1)

#     if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
#       echo "${indexNo}番目のノードは存在しません"
#       read -s -n 1 c
#       bash "${0}" "${inputFile}" 't'
#       exit 0
#     else
#       if [[ ${indexNo} -eq 1 ]]; then
#         cat "${inputFile}" | { sed -n "1, $((endLine-1))p" > "${tmpfileB}"; cat >/dev/null;}
#         tail -n +$((endLine)) "${inputFile}" > "${tmpfileF}"
#       else
#         if [[ ${indexNo} -eq $maxCnt ]]; then
#           cat "${inputFile}" | { head -n "$((startLine-1))" > "${tmpfileH}"; cat >/dev/null;}
#           cat "${inputFile}" | { tail -n +$((startLine))  > "${tmpfileB}"; cat >/dev/null;}
#           echo '' > "${tmpfileF}"
#         else
#           cat "${inputFile}" | { head -n "$((startLine-1))" > "${tmpfileH}"; cat >/dev/null;}
#           cat "${inputFile}" | { sed -n "$((startLine)), $((endLine-1))p" > "${tmpfileB}"; cat >/dev/null;} 
#           tail -n +$((endLine)) "${inputFile}" > "${tmpfileF}"
#         fi
#       fi
#     fi

#     case "${action}" in
#       'e')  "${selected_editor}" "${tmpfileB}"
#             wait
#             sed -i -e '$a\' "${tmpfileB}" #編集の結果末尾に改行がない場合'
#             cat "${tmpfileH}" "${tmpfileB}" "${tmpfileF}" > "${inputFile}"
#             ;;
#       'd')  cat "${tmpfileH}" "${tmpfileF}" > "${inputFile}"
#             ;;
#       'v')  "${selected_viewer}" "${tmpfileB}"
#             ;;
#       *)    echo '不正な引数です。'
#     esac

#     bash "${0}" "${inputFile}" 't'
#     exit 0

#   fi
# }


