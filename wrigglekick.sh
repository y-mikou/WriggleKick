#!/bin/bash

: "ノード検出" && {
  ##############################################################################
  # グローバル配列
  ##############################################################################
  declare -a nodeStartLines
  declare -a nodeEndLines
  declare -a nodeDepths
  declare -a nodeTitles
  declare -a nodePreview

  ##############################################################################
  # ノード検出
  # 入力ファイルのノード構成を検出してグローバル設定する
  # 引数:なし(グローバル変数のみ参照)
  # グローバル変数設定:最大ノード数(maxNodeCnt)、各種配列
  ##############################################################################
  function detectNode {
    
    readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})

    maxNodeCnt="${#indexlist[@]}"
    maxLineCnt="$( cat "${inputFile}" | wc -l  )"

    nodeStartLines=()
    nodeEndLines=()
    nodeDepths=()
    nodeTitles=()
    # nodePreview=()

    for i in $(seq 1 ${maxNodeCnt}); do
      local entry="${indexlist[$((i-1))]}"
      local startLine="${entry%%:*}"
      local content="${entry#*:}"      
      local endLine

      if [[ ${i} -ne ${maxNodeCnt} ]]; then
        local nextEntry="${indexlist[${i}]}"
        local nextStartLine="${nextEntry%%:*}"
        endLine=$((nextStartLine - 1))
      else
        endLine="${maxLineCnt}"
      fi
      
      local depth="${content}"
      depth="${depth%%[^.]*}"
      depth="${#depth}"
      
      local title="${content##*.}"

      nodeStartLines+=("${startLine}")
      nodeEndLines+=("${endLine}")
      nodeDepths+=("${depth}")
      nodeTitles+=("${title}")

      # local preview="$( getOutset ${i} 10 )"
      # nodePreview+=("${preview}")

    done
    # maxDepth=$(for element in "${nodeDepths[@]}"; do echo "$element"; done | sort -n | tail -n 1)
    # maxTitleLength=$(for element in "${nodeTitles[@]}"; do echo "$element"; done | sort -n | tail -n 1 | wc -c)
    # padSeed=$(( ${maxDepth} + ${maxTitleLength} ))

  }
}

: "冒頭取得" && {
  ##############################################################################
  # 冒頭取得
  # 対象ノードの冒頭n文字を取得する。ノードの1行目はタイトルなので2行目以降
  # 引数1:対象ノード番号
  # 引数2:取得文字
  # 標準出力:対象ノードの冒頭
  ##############################################################################
  function getOutset {
    
    local selectNode="${1}"
    local getCharactorAmount="${2}"

    local startLineGetOutset="$( getLineNo ${selectNode} 1 )"
    local endLineGetOutset="$(   getLineNo ${selectNode} 9 )"
    local outset=''

    if [[ ${startLineGetOutset} -eq ${endLineGetOutset} ]] ; then
      outset=''
    else
      startLineGetOutset="$(( ${startLineGetOutset} + 1 ))"
      outset="$( cat ${inputFile} | sed -n ${startLineGetOutset}p  | tr -d '\n' )"
      outset="${outset:0:${getCharactorAmount}}"
    fi

    echo "${outset}"

  }
}


: "深さ取得" && {
  ##############################################################################
  # 深さ取得
  # 対象ノードの深さを取得する
  # 引数1:対象ノード番号
  # 標準出力:対象ノードの深さ
  ##############################################################################
  function getDepth {
    
    local selectNode="${1}"
    echo "${nodeDepths[$((selectNode-1))]}"

  }
}

: "ノード行範囲取得" && {
  ##############################################################################
  # 行番号取得
  # ノード番号から、対象ノードの開始行数と終了行数を取得する
  # 引数1:対象ノード番号
  # 引数2:出力する行の種類　1:開始行番号を出力/9:終了行番号を出力
  # 標準出力:引数2が1……開始行番号
  #               2……終了行番号
  #               なし、もしくはそれ以外……開始行番号 終了行番号
  ##############################################################################
  function getLineNo {
    local selectNodeNo="${1}"
    local mode="${2}"
    local startLine="${nodeStartLines[$((selectNodeNo-1))]}"
    local endLine="${nodeEndLines[$((selectNodeNo-1))]}"

    case "${mode}" in
      '') echo "${startLine} ${endLine}" ;;
      1) echo  "${startLine}" ;;
      9) echo  "${endLine}" ;;
      *) echo  "${startLine} ${endLine}" ;;
    esac

  }
}

: "タイトル取得" && {
  ##############################################################################
  # ノードタイトル取得
  # 対象ノードのタイトルを取得する
  # 引数1:対象ノード番号
  # 戻り値:なし
  # 標準出力:対象ノードのタイトル
  ##############################################################################
  function getNodeTitle {
    
    local selectNode="${1}"
    echo "${nodeTitles[$((selectNode-1))]}"

  }
}

: "グループ範囲取得系" && {
  ##############################################################################
  # 選択ノードの所属するグループの範囲(ノード番号)を取得する
  # 引数1:対象ノード番号
  # 引数2:出力する行の種類　1:開始行番号を出力/9:終了行番号を出力
  # 標準出力:引数2が1……開始行番号
  #               2……終了行番号
  #               なし、もしくはそれ以外……開始行番号 終了行番号
  ##############################################################################
  function getNodeNoInGroup {
    local selectNodeNo="${1}"
    local mode="${2}"
    local selectNoedDepth="$( getDepth ${selectNodeNo} )"

    startNodeSelectGroup="${selectNodeNo}"
    endNodeSelectGroup="${maxNodeCnt}"

    for i in $( seq "$(( ${selectNodeNo} + 1 ))" "${maxNodeCnt}") ;
    do
      depthCheck="$( getDepth ${i} )"
      if [[ ${depthCheck} -le ${selectNoedDepth} ]] ; then
        endNodeSelectGroup="$(( ${i} - 1 ))"
        break
      fi
    done

    case "${mode}" in
      '') echo "${startNodeSelectGroup} ${endNodeSelectGroup}" ;;
      1) echo  "${startNodeSelectGroup}" ;;
      9) echo  "${endNodeSelectGroup}" ;;
      *) echo  "${startNodeSelectGroup} ${endNodeSelectGroup}" ;;
    esac
  }

  ##############################################################################
  # 選択ノードの所属するグループの一つ上/下のグループの範囲(ノード番号)を取得する
  # 引数1:対象ノード番号
  # 引数2:方向　u:上/d:下
  # 引数3:出力する行の種類　1:開始行番号を出力/9:終了行番号を出力
  # 戻り値:（グループがないとき）e
  # 標準出力:引数2が1……開始行番号
  #               2……終了行番号
  #               なし、もしくはそれ以外……開始行番号 終了行番号
  ##############################################################################
  function getTargetNodeNoInGroup {
    local selectNodeNo="${1}"
    local direction="${2}"
    local mode="${3}"
    local selectNodeDepth="$( getDepth ${selectNodeNo} )"

    case "${direction}" in
      '')   local inc=1
            local goal="${maxNodeCnt}"
            ;;
      [uU]) local inc=-1
            local goal=1
            ;;
      [dD]) local inc=1
            local goal="${maxNodeCnt}"
            ;;
      *)    local inc=1
            local goal=1
            ;;
    esac

    for i in $( seq $(( "${selectNodeNo}" + "${inc}" )) "${inc}" "${goal}" ) ;
    do
      depth="$( getDepth ${i} )"
      if [[ ${depth} -le ${selectNodeDepth} ]] ; then
        returnNodeNo="${i}"
        break
      fi
    done

    if [[ ${depth} -ne ${selectNodeDepth} ]] ; then
      returnNodeNo=''
      exit 100
    fi

    local TargetGroupFromTo="$(getNodeNoInGroup ${returnNodeNo} '' )"
    local startnodeTargetGroup="$( echo ${TargetGroupFromTo} | cut -d ' ' -f 1 )"
    local endnodeTargetGroup="$(   echo ${TargetGroupFromTo} | cut -d ' ' -f 2 )"

    case "${mode}" in
      '') echo "${startnodeTargetGroup} ${endnodeTargetGroup}" ;;
      1) echo  "${startnodeTargetGroup}" ;;
      9) echo  "${endnodeTargetGroup}" ;;
      *) echo  "${startnodeTargetGroup} ${endnodeTargetGroup}" ;;
    esac
  }
}

: "ツリー表示系" && {
  ##############################################################################
  # ツリー表示する
  # t:通常ツリー
  # tl:開始行番号付きツリー表示
  # ta:開始終了行番号深さ付きツリー表示
  # 先頭から末尾を指定してツリービューを呼び出すラッパー
  ##############################################################################
  function displayTree {
    tree 1 "${maxNodeCnt}"
  }

  ##############################################################################
  # 対象グループをフォーカス表示する
  # f:通常フォーカス表示
  # fl:開始行番号付きフォーカス表示
  # fa:開始終了行番号深さ付きフォーカス表示
  # グループ(開始ノードと終了ノード)を指定してツリービューを呼び出すラッパー
  ##############################################################################
  function focusMode {

    local SelectGroupNodeFromTo="$(getNodeNoInGroup ${indexNo} '' )"
    local startNodeSelectGroup="$( echo ${SelectGroupNodeFromTo} | cut -d ' ' -f 1 )"
    local endNodeSelectGroup="$( echo ${SelectGroupNodeFromTo} | cut -d ' ' -f 2 )"
    tree "${startNodeSelectGroup}" "${endNodeSelectGroup}"
  }

  ##############################################################################
  # ツリー表示する
  # t:通常ツリー
  # tl:開始行番号付きツリー表示
  # ta:開始終了行番号深さ付きツリー表示
  # 引数1: 開始グループ番号
  # 引数2: 終了グループ番号
  ##############################################################################
  function tree {

    local startNodeSelectGroup="${1}"
    local endNodeSelectGroup="${2}"

    printf "【$(basename ${inputFile})】"
    case "${char1}" in
      't')  echo '';;
      'f')  echo " ★ フォーカス表示中";;
      *)    echo '';;
    esac

    case "${char2}" in
      '')  echo 'ノード  アウトライン'
            echo '------+------------'
            ;;
      'l') echo 'ノード 行番号    アウトライン'
            echo '------+--------+------------'
            ;;
      'a') echo 'ノード 行番号            深さ アウトライン'
            echo '------+--------+--------+---+------------'
            ;;
      *)    ;;
    esac

    seq "${startNodeSelectGroup}" "${endNodeSelectGroup}" | {
      while read -r cnt ; do
        startLine="$( getLineNo ${cnt} 1 )"
        endLine="$(   getLineNo ${cnt} 9 )"
        depth="$( getDepth ${cnt} )"

        titleLength="${nodeTitles[ $(( cnt-1 )) ]}"
        titleLength="${#titleLength}"

        padding="$(( ${padSeed} - ${depth} - ${titleLength} ))"

        printf "%06d" "${cnt}"

        case "${char2}" in
          '')  :
                ;;
          'l') printf " %08d" "${startLine}"
                ;;
          'a') printf " %08d~%08d %03d" "${startLine}" "${endLine}" "${depth}"
                ;;
          *)    ;;
        esac

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
        echo "$( getNodeTitle ${cnt} )"

        # printf "$( getNodeTitle ${cnt} )"
        # seq ${padding} | while read -r line; do printf '  '; done
        # echo "${nodePreview[$((${cnt}-1))]}"

      done

    }

    echo '❓️引数なしでhelp参照'
    exit 0
   
  }
}

: "配下ノード閲覧コマンド" && {
  ##############################################################################
  # 選択ノードから、下方向に選択ノードよりも深さが深い限り続くノード範囲を対象に、閲覧する
  # 引数:ノード番号
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function groupView {
    local selectNode="${indexNo}"
    local tgtGroup="$( getNodeNoInGroup ${selectNode} '' )"
    local startLineSelectGroup="$( getLineNo $( echo ${tgtGroup} | cut -d ' ' -f 1 ) 1 )"
    local endLineSelectGroup="$( getLineNo $( echo ${tgtGroup} | cut -d ' ' -f 2 ) 9 )"

    cat "${inputFile}" | sed -sn "${startLineSelectGroup},${endLineSelectGroup}p" > "${tmpfileTarget}"
    "${selected_viewer}" "${tmpfileTarget}"
    bash "${0}" "${inputFile}" 't'
    exit 0
  }
}

: "ノード削除・ノード編集・単一ノード閲覧コマンド" && {
  ##############################################################################
  # d:対象のノードを削除する
  # e:対象のノードを編集する
  # v:対象のノードを閲覧する
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function singleNodeOperations {

    selectNodeLineFromTo="$( getLineNo ${indexNo} '' )"
    startLineSelectNode="$( echo ${selectNodeLineFromTo} | cut -d ' ' -f 1 )"
    endLineSelectNode="$(   echo ${selectNodeLineFromTo} | cut -d ' ' -f 2 )"

    endLineHeader="$(( ${startLineSelectNode} -1 ))"
    startLineFooter="$(( ${endLineSelectNode} +1 ))"

    (
      if [[ ${indexNo} -eq 1 ]]; then
        printf '' > "${tmpfileHeader}"
      else
        cat "${inputFile}" | { head -n "${endLineHeader}" > "${tmpfileHeader}"; cat >/dev/null;}
      fi
      wait
    )
    (
      if [[ ${indexNo} -eq 1 ]] ; then
        cat "${inputFile}" | { sed -n "1, ${endLineSelectNode}p" > "${tmpfileSelect}"; cat >/dev/null;}
      else
        if [[ ${indexNo} -eq ${maxNodeCnt} ]] ; then
          cat "${inputFile}" | { tail -n +${startLineSelectNode}  > "${tmpfileSelect}"; cat >/dev/null;}
        else
          echo "${startLineSelectNode} ${endLineSelectNode}p"
          cat "${inputFile}" | { sed -n "${startLineSelectNode},${endLineSelectNode}p" > "${tmpfileSelect}"; cat >/dev/null;}
        fi
      fi
      wait
    )
    (
      if [[ ${indexNo} -eq ${maxNodeCnt} ]] ; then
        printf '' > "${tmpfileFooter}"
      else
        tail -n +"${startLineFooter}" "${inputFile}" > "${tmpfileFooter}"
      fi
      wait
    )

    case "${action}" in
      'e')  "${selected_editor}" "${tmpfileSelect}"
            wait
            sed -i -e '$a\' "${tmpfileSelect}" #編集の結果末尾に改行がない場合'
            cat "${tmpfileHeader}" "${tmpfileSelect}" "${tmpfileFooter}" > "${inputFile}"
            ;;
      'd')  cat "${tmpfileHeader}" "${tmpfileFooter}" > "${inputFile}"
            ;;
      'v')  "${selected_viewer}" "${tmpfileSelect}"
            ;;
      *)    echo '不正な引数です。'
            exit 9
            ;;
    esac

    bash "${0}" "${inputFile}" 't'
    exit 0
  }
}

: "ノード挿入コマンド" && {
  ##############################################################################
  # 対象のノードの下に新しいノードを挿入する
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function insertNode {
    
    nlString='New Node'
    endLinePreviousNode="$( getLineNo ${indexNo} 9 )"
    startLineNextNode="$(   getLineNo $(( ${indexNo} +1 )) 1 )"

    depth="$( getDepth ${indexNo} )"
    dots="$(seq ${depth} | while read -r line; do printf '.'; done)"

    echo "${dots}${nlString}" > "${tmpfileSelect}"
    cat "${inputFile}" | { head -n "${endLinePreviousNode}" > "${tmpfileHeader}"; cat >/dev/null;}

    if [[ ${indexNo} -eq ${maxNodeCnt} ]] ;then
      awk 1 "${inputFile}" "${tmpfileSelect}" > "${tmpfile1}"
      cat "${tmpfile1}" > "${inputFile}"

    else
      cat "${inputFile}" | { tail -n +${startLineNextNode}  > "${tmpfileFooter}"; cat >/dev/null;}
      cat "${tmpfileHeader}" "${tmpfileSelect}" "${tmpfileFooter}" > "${inputFile}"
    fi

    bash "${0}" "${inputFile}" 't'
    exit 0
  }
}

: "単ノード深さ変更コマンド" && {
  ##############################################################################
  # 対象のノード一つだけの深さを変更する
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function slideNode {

    tgtLine="$(getLineNo ${indexNo} 1 )"

    case "${char2}" in
      'l')  sed -i -e "$tgtLine s/^\.\./\./g" "${inputFile}"
            ;;
      'r')  sed -i -e "$tgtLine s/^/\./g" "${inputFile}"
            ;;
      *)    echo 'err'
            exit 9
            ;;
    esac

    bash "${0}" "${inputFile}" 't'
    exit 0

  }
}

: "単ノード上下交換コマンド" && {
  ##############################################################################
  # 対象のノード一つだけを上下に移動する(指定の方向のノードと入れ替える)
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function swapNode {

    local indexTargetNode=''
    local indexNextNode=''
    local endLinePreviousNode=''
    local startLineTargetNode=''
    local endLineTargetNode=''
    local targetNodeLineFromTo=''

    local indexSelectNode="$(( ${indexNo}    ))"
    local selectNodeLineFromTo="$( getLineNo ${indexSelectNode} '' )"
    local startLineSelectNode="$( echo ${selectNodeLineFromTo} | cut -d ' ' -f 1 )"
    local endLineSelectNode="$(   echo ${selectNodeLineFromTo} | cut -d ' ' -f 2 )"

    case "${char2}" in
      'u')  indexTargetNode="$(( ${indexNo} -1 ))"
            #indexSelectNode="$(( ${indexNo}    ))"
            indexNextNode="$((   ${indexNo} +1 ))"

            endLinePreviousNode="$(( $( getLineNo ${indexTargetNode} 1 ) - 1 ))"

            targetNodeLineFromTo="$( getLineNo ${indexTargetNode} '' )"
            startLineTargetNode="$( echo ${targetNodeLineFromTo} | cut -d ' ' -f 1 )"
            endLineTargetNode="$(   echo ${targetNodeLineFromTo} | cut -d ' ' -f 2 )"

            if [[ ${indexNo} -eq ${maxNodeCnt} ]] ; then
              startLineNextNode=''
            else
              startLineNextNode="$( getLineNo ${indexNextNode} 1 )"
            fi
            
            (
              cat "${inputFile}" | { head -n "${endLinePreviousNode}" > "${tmpfileHeader}"; cat >/dev/null;}
              cat "${inputFile}" | { sed -sn "${startLineTargetNode},${endLineTargetNode}p" > "${tmpfileTarget}"; cat >/dev/null;}
              cat "${inputFile}" | { sed -sn "${startLineSelectNode},${endLineSelectNode}p" > "${tmpfileSelect}"; cat >/dev/null;}
              if [[ ! "${startLineNextNode}" = '' ]] ; then 
                tail -n +"${startLineNextNode}" "${inputFile}" > "${tmpfileFooter}"
              fi
              wait
            )
            (
              cat "${tmpfileHeader}" "${tmpfileSelect}" > "${tmpfile1}"
              cat "${tmpfileTarget}" "${tmpfileFooter}" > "${tmpfile2}"
              wait
            )
            cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"

            ;;

      'd')  indexPreviousNode="$(( ${indexNo} -1 ))"
            #indexSelectNode="$((   ${indexNo}    ))"
            indexTargetNode="$((   ${indexNo} +1 ))"
            indexNextNode="$((     ${indexNo} +2 ))"
            
            endLinePreviousNode="$( getLineNo ${indexPreviousNode} 9 )"

            targetNodeLineFromTo="$( getLineNo ${indexTargetNode} '' )"
            startLineTargetNode="$( echo ${targetNodeLineFromTo} | cut -d ' ' -f 1 )"

            if [[ ${indexNo} -eq ${maxNodeCnt} ]] ; then
              endLineTargetNode="$(cat "${inputFile}" | wc -l )"
            else
              endLineTargetNode="$( echo ${targetNodeLineFromTo} | cut -d ' ' -f 2 )"
              startLineNextNode="$( getLineNo ${indexNextNode}   1 )"
            fi
            (
              if [[ ${indexNo} -eq 1 ]] ; then
                echo '' > "${tmpfileHeader}"
              else
                cat "${inputFile}" | { head -n "${endLinePreviousNode}" > "${tmpfileHeader}"; cat >/dev/null;}
              fi
              cat "${inputFile}" | { sed -sn "${startLineTargetNode},${endLineTargetNode}p" > "${tmpfileTarget}"; cat >/dev/null;} 
              cat "${inputFile}" | { sed -sn "${startLineSelectNode},${endLineSelectNode}p" > "${tmpfileSelect}"; cat >/dev/null;}
              if [[ ! ${startLineNextNode} = '' ]] ; then 
                tail -n +"${startLineNextNode}" "${inputFile}" > "${tmpfileFooter}"
              fi
              wait
            )
            (
              cat "${tmpfileHeader}" "${tmpfileTarget}" > "${tmpfile1}"
              cat "${tmpfileSelect}" "${tmpfileFooter}" > "${tmpfile2}"
              wait
            )
            cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"
            ;;

      *)    echo 'err'
            exit 9
            ;;
    esac

    bash "${0}" "${inputFile}" 't'
    exit 0
  }
}

: "配下ノード深さ変更コマンド" && {
  ##############################################################################
  # 対象のノードとその配下の深さを、一緒に変更する
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function slideGroup {

    local SelectGroupNodeFromTo="$( getNodeNoInGroup ${indexNo} '' )"
    local startNodeSelectGroup="$( echo ${SelectGroupNodeFromTo} | cut -d ' ' -f 1 )"
    local endNodeSelectGroup="$(   echo ${SelectGroupNodeFromTo} | cut -d ' ' -f 2 )"

    case "${char3}" in
      'l')  for i in $(seq "${startNodeSelectGroup}" "${endNodeSelectGroup}") ;
            do
              tgtLine="$( getLineNo ${i} 1 )"
              sed -i -e "${tgtLine} s/^\.\./\./g" "${inputFile}"
            done
            ;;
      'r')  for i in $(seq "${startNodeSelectGroup}" "${endNodeSelectGroup}") ;
            do
              tgtLine="$( getLineNo ${i} 1 )"
              sed -i -e "${tgtLine} s/^\./\.\./g" "${inputFile}"
            done
            ;;
      *)    echo 'err'
            read -s -n 1 c
            exit 9
            ;;
    esac

    bash "${0}" "${inputFile}" 't'
    exit 0

  }
}

: "配下ノード上下交換コマンド" && {
  ##############################################################################
  # 対象のノードとその配下と、対象ノードと同じ高さの上下ノードとその配下とを、同時に入れ替える
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function swapGroup {

    local selectNodeDepth=0
    local depthCheck=0
    local direction="${char3}"

    local selectNodeLineFromTo=''
    local startLineSelectGroup=''
    local endLineSelectGroup=''

    local targetNodeLineFromTo=''
    local startLineTargetGroup=''
    local endLineTargetGroup=''

    : "選択グループ情報を取得" && {
      selectNodeLineFromTo="$( getNodeNoInGroup ${indexNo} '' )"
      startLineSelectGroup="$(getLineNo $( echo $( echo ${selectNodeLineFromTo} | cut -d ' ' -f 1 ) | cut -d ' ' -f 1 ) 1 )"
      endLineSelectGroup="$(  getLineNo $( echo $( echo ${selectNodeLineFromTo} | cut -d ' ' -f 2 ) | cut -d ' ' -f 1 ) 9 )"

    }

    : "移動先グループ情報を取得" && {
      #上移動の場合
      ##かつ対象ノードが一番上の場合
      targetNodeLineFromTo="$(getTargetNodeNoInGroup "${indexNo}" "${direction}" '' )" 
      if [[ "${?}" -ne 0 ]] ; then
        echo '交換移動可能なグループがありません'
        read -s -n 1 c
        bash "${0}" "${inputFile}" 't'
        exit 0
      else
        startLineTargetGroup="$(getLineNo $( echo $( echo ${targetNodeLineFromTo} | cut -d ' ' -f 1 ) | cut -d ' ' -f 1 ) 1 )"
        endLineTargetGroup="$(  getLineNo $( echo $( echo ${targetNodeLineFromTo} | cut -d ' ' -f 2 ) | cut -d ' ' -f 1 ) 9 )"
      fi
    }

    : "ヘッダ部分の情報を取得" && {
      # directionがu(上と交換)の場合:1行目〜「移動先グループの先頭ノードの先頭行の１行前(startLineTargetGroup-1)」
      # directionがd(下と交換)の場合:1行目〜「選択グループの先頭ノードの先頭行の1行前(startLineSelectGroup-1)
      
      if [[ ${startLineTargetGroup} -eq 1 ]] ; then
        startLineHeaderGroup=0
        endLineHeaderGroup=0
      else
        startLineHeaderGroup=1
        case "${direction}" in
          [uU]) endLineHeaderGroup="$(( ${startLineTargetGroup} -1 ))"
                ;;
          [dD]) endLineHeaderGroup="$(( ${startLineSelectGroup} -1 ))"
                ;;
          *)  echo 'err'
              ;;
        esac
      fi
    }

    : "フッタ部分の情報を取得" && {
      # directionがu(上と交換)の場合:「選択グループの末尾ノードの末尾行の1行後ろ(endLineSelectGroup+1)」〜最終行
      # directionがd(下と交換)の場合:「移動先グループの末尾ノードの末尾行の1行後ろ(endLineTargetGroup+1)」〜最終行

      if [[ ${endLineTargetGroup} -eq ${maxLineCnt} ]] ; then
        startLineFooterGroup="${maxLineCnt}"
        endLineFooterGroup="${maxLineCnt}"
      else
        case "${direction}" in
          [uU]) startLineFooterGroup="$(( ${endLineSelectGroup} +1 ))"
                ;;
          [dD]) startLineFooterGroup="$(( ${endLineTargetGroup} +1 ))"
                ;;
          *)  echo 'err'
              exit 9
              ;;
        esac
        endLineFooterGroup="${maxLineCnt}"
      fi
    }

   if [[ ${endLineHeaderGroup} -ne 0 ]] ; then
     cat "${inputFile}" | { head -n "${endLineHeaderGroup}" > "${tmpfileHeader}"; cat >/dev/null;}
    else
      printf '' > "${tmpfileHeader}"
    fi

    cat "${inputFile}" | { sed -sn "${startLineTargetGroup},${endLineTargetGroup}p" > "${tmpfileTarget}"; cat >/dev/null;} 
    cat "${inputFile}" | { sed -sn "${startLineSelectGroup},${endLineSelectGroup}p" > "${tmpfileSelect}"; cat >/dev/null;}

    if [[ ${startLineFooterGroup} -ne ${maxLineCnt} ]] ; then
      tail -n +"${startLineFooterGroup}" "${inputFile}" > "${tmpfileFooter}"
    else
      printf '' > "${tmpfileFooter}"
    fi

    (
      case "${direction}" in
        [uU]) cat "${tmpfileHeader}" "${tmpfileSelect}" > "${tmpfile1}"
              cat "${tmpfileTarget}" "${tmpfileFooter}" > "${tmpfile2}"
              ;;
        [dD]) cat "${tmpfileHeader}" "${tmpfileTarget}" > "${tmpfile1}"
              cat "${tmpfileSelect}" "${tmpfileFooter}" > "${tmpfile2}"
              ;;
        *)    echo 'err'
              read -s -n 1 c
              exit 9
              ;;
      esac
      wait
    )

    cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"
    bash "${0}" "${inputFile}" 't'
    exit 0

  }
}

: "配下ノード削除コマンド" && {
  ##############################################################################
  # 対象のノードとその配下を削除する
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function deleteGroup {

    local selectGroupNodeFromTo="$( getNodeNoInGroup ${indexNo} '' )"
    local startNodeSelectGroup="$( echo ${selectGroupNodeFromTo} | cut -d ' ' -f 1 )"
    local endNodeSelectGroup="$(   echo ${selectGroupNodeFromTo} | cut -d ' ' -f 2 )"

    local startLineSelectGroup="$( getLineNo ${startNodeSelectGroup} 1 )"
    local endLineSelectGroup="$(   getLineNo ${endNodeSelectGroup} 9 )"

    local endLineHeader="$(( ${startLineSelectGroup} - 1 ))"
    local startLineFooter="$(( ${endLineSelectGroup} + 1 ))"

    (
      if [[ ${endLineHeader} -eq 0 ]]; then
        printf '' > "${tmpfileHeader}"
      else
        cat "${inputFile}" | { head -n "${endLineHeader}" > "${tmpfileHeader}"; cat >/dev/null;}
      fi
      wait
    )
    (
      if [[ ${startLineFooter} -gt ${maxLineCnt} ]] ; then
        printf '' > "${tmpfileFooter}"
      else
        tail -n +"${startLineFooter}" "${inputFile}" > "${tmpfileFooter}"
      fi
      wait
    )

    cat "${tmpfileHeader}" "${tmpfileFooter}" > "${inputFile}"

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
    local MAX_BACKUP_COUNT="${2}"
  
    #3つ以上作る気がない
    #echo 'バックアップ作成'
    if [[ -f "./$(basename ${orgFile})_bk_2" ]] ; then 
      cp -f "./$(basename ${orgFile})_bk_2" "./$(basename ${orgFile})_bk_3"
    fi
    if [[ -f "./$(basename ${orgFile})_bk_1" ]] ; then 
      cp -f "./$(basename ${orgFile})_bk_1" "./$(basename ${orgFile})_bk_2"
    fi
    cp -f "./$(basename ${orgFile})" "./$(basename ${orgFile})_bk_1"
  }
}

: "初期処理" && {
  ##############################################################################
  # 初期処理
  ##############################################################################
  function myInit {

    #ノード検出
    detectNode
    
    #エディタの設定
    #editorList配列の優先順で存在するコマンドに決定される。
    #ユーザによる書き換えも想定
    #(selected_editor部分を任意のエディター起動コマンドに変更)
    editorList=('selected_editor' 'edit' 'micro' 'nano' 'vi' 'ed')
                #^^^^^^^^^^^^^^^edit here
    for itemE in "${editorList[@]}" ; do
      #コマンドがエラーを返すか否かで判断
      \command -v "${itemE}" >/dev/null 2>&1
      if [[ ${?} = 0 ]] ; then
        selected_editor="${itemE}"
        break
      fi
    done

    #ビューワの設定
    #viewerList配列の優先順で存在するコマンドに決定される。
    #ユーザによる書き換えも想定
    #(selected_viewer部分を任意のビューワ起動コマンドに変更)
    viewerList=('selected_viewer' 'less' 'more' 'view' 'cat')
                #^^^^^^^^^^^^^^^edit here
    for itemV in "${viewerList[@]}" ; do
      #コマンドがエラーを返すか否かで判断
      \command -v "${itemV}" >/dev/null 2>&1
      if [[ ${?} = 0 ]] ; then
        selected_viewer="${itemV}"
        break
      fi
    done

    ################################################
    # 動作指定の読み替え
    ################################################

    #(存在する)ファイルのみを指定した場合、ツリービューに読み替え
    if [[ ${#action} = 0 ]] ; then
      echo "動作指定がないためツリー表示します"
      read -s -n 1 c
      bash "${0}" "${inputFile}" 't'
      exit 0
    fi

    #動作指定を省略して段落を指定した場合、編集に読み替え
    if [[ ${action} =~ ^[0-9]+$ ]] && [[ ${#indexNo} = 0 ]] ; then
      echo "段落のみが指定されたため、編集モードにします"
      read -s -n 1 c
      bash "${0}" "${inputFile}" 'e' "${action}"
      exit 0
    fi

    if [[ -f ${inputFile} ]] && [[ ${#action} = 0 ]] ; then
      bash "${0}" "${inputFile}" 't'
      return 0
    fi

    ######################################
    #バックアップ作成
    ######################################
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
    
    local depth=$(getDepth ${indexNo})

    #動作指定のチェック
    allowActionList=('h' 'e' 'd' 'i' 't' 'tl' 'ta' 'f' 'fl' 'fa' 'v' 'gv' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd' 'x')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -ne 0 ]] ; then
      echo '引数2:無効なアクションです'
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=('e' 'd' 'i' 'f' 'fl' 'fa' 'v' 'gv' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] ; then
      if [[ ${indexNo} = '' ]] ; then
        echo "ノードを指定してください"
        read -s -n 1 c
        return 1
      fi
    fi
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] ; then
      if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxNodeCnt} ]] ; then
        echo "${indexNo}番目のノードは存在しません"
        read -s -n 1 c
        return 1
      fi
    fi

    #動作指定とノード番号のチェック(ノード状態の取得が必要なチェックは後続で実施)
    unset allowActionList
    allowActionList=('ml' 'gml')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] && [[ ${depth} -le 1 ]] ; then
      echo "ノード番号${indexNo}はこれ以上浅く(左に移動)できません"
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=('mr' 'gmr')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] && [[ ${depth} -ge 10 ]] ; then
      echo "ノード番号${indexNo}の深さは${depth}です。これ以上深く(右に移動)できません"
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=('mu' 'gmu')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] && [[ ${indexNo} -eq 1 ]] ; then
      echo '引数2:1番目のノードは上に移動できません'
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=('md' 'gmd')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] && [[ ${indexNo} -ge ${maxNodeCnt} ]] ; then
      echo "引数2:${indexNo}番目のノードは下に移動できません"
      read -s -n 1 c
      return 1
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
    [[ -f "${tmpfileHeader}" ]] && rm -f "${tmpfileHeader}"
    [[ -f "${tmpfileSelect}" ]] && rm -f "${tmpfileSelect}"
    [[ -f "${tmpfileTarget}" ]] && rm -f "${tmpfileTarget}"
    [[ -f "${tmpfileFooter}" ]] && rm -f "${tmpfileFooter}"
  }

  ##############################################################################
  # 一時ファイル作成
  # 引数:なし
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function makeTmpfile {

    # 一時ファイルを作る
    tmpfileHeader=$(mktemp)
    tmpfileSelect=$(mktemp)
    tmpfileTarget=$(mktemp)
    tmpfileFooter=$(mktemp)
    tmpfile1=$(mktemp)
    tmpfile2=$(mktemp)
  }
}

: "ヘルプ表示" && {
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
    echo '　　　　　tla...行番号範囲深さ付きツリービュー'
    echo '　　　　　f.....フォーカスビュー'
    echo '　　　　　fl....行番号付きフォーカスビュー'
    echo '　　　　　fla...行番号範囲深さ付きフォーカスビュー'
    echo '　　　　　v.....対象ノードの閲覧'
    echo '　　　　　gv....対象ノードの配下ノードを横断的に閲覧'
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
    echo '　　　　　数字...対象ノードを編集(eと引数3を省略)'
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
    indexNo="${3}"

    #対象ファイルの存在チェック
    if [[ ! -f ${inputFile} ]] ; then
      echo "${inputFile} なんてファイルないです"
      read -s -n 1 c
      exit 100
    fi

    myInit                      # 初期処理

    if [[ ${maxNodeCnt} -eq 0 ]] ; then
      echo 'ノードがありません。先頭に第一ノードを追加します' 
      printf '%s\n' 0a '.1st Node' . x | ex "${inputFile}"
      read -s -n 1 c
      bash "${0}" "${inputFile}" 't'
      exit 0
    fi

    #パラメータチェック
    parameterCheck
    if [[ ${?} -ne 0 ]] ; then 
      exit 1
    fi

    makeBackup "${inputFile}" 3 # バックアップ作成。今のところ3世代固定
    makeTmpfile                 # 一時ファイルを作成

    char1="${action:0:1}"
    char2="${action:1:1}"
    char3="${action:2:1}"

    clear

    case "${char1}" in
      'x')  getOutset "${indexNo}" 10
            ;;
      'h')  displayHelp
            ;;
      't')  displayTree
            ;;
      'm')  case "${char2}" in 
              [ud]) swapNode
                    ;;
              [lr]) slideNode
                    ;;
              *)  echo 'err'
                  ;;
            esac
            ;;
      'g')  case "${char2}" in 
              'v')  groupView
                    ;;
              *)  case "${char3}" in 
                    [ud]) swapGroup
                          ;;
                    [lr]) slideGroup
                          ;;
                    [lr]) slideGroup
                          ;;
                    *)  echo 'err'
                        ;;
                  esac
            esac
            ;;
      'f')  focusMode
            ;;
      'i')  insertNode
            ;;
      [edv])  singleNodeOperations
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
 
