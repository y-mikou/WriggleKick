##!/bin/bash

: "ノード検出" && {
  ##############################################################################
  # ノード検出
  # 入力ファイルのノード構成を検出してグローバル設定する
  # 今は最大ノード数のみ
  # 引数:なし(グローバル変数のみ参照)
  # グローバル変数設定:最大ノード数(maxCnt)
  ##############################################################################
  function detectNode {
    
    readarray -t indexlist < <(grep -nP '^\.+.+' ${inputFile})

    maxCnt="${#indexlist[@]}"

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
    
    selectNode="${1}"

    local replaceFrom="$(echo ${indexlist[(( selectNode - 1 ))]} | cut -d: -f 2)"
    echo "${replaceFrom}" | grep -oP '^\.+' | grep -o '.' | wc -l

  }
}

: "ノード行範囲取得" && {
  ##############################################################################
  # 行番号取得
  # ノード番号から、対象ノードの開始行数と終了行数を取得する
  # 引数1:対象ノード番号
  # 引数2:出力する行の種類　1:開始行番号を出力/9:終了行番号を出力
  # 標準出力:開始行番号 終了行番号
  ##############################################################################
  function getLineNo {
    local selectNodeNo=${1}
    local mode="${2}"
    local startLine="$( echo "${indexlist[((selectNodeNo-1))]}" | cut -d: -f 1 )"
 
    if [[ ${selectNodeNo} -ne $((maxCnt)) ]] ; then
      local endLine="$(( $( echo ${indexlist[((selectNodeNo))]} | cut -d: -f 1 ) -1 ))"
    else
      local endLine="$( cat "${inputFile}" | wc -l  )"
    fi
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
  # 戻り値:0(成功)/9(失敗)
  # 標準出力:対象ノードのタイトル
  ##############################################################################
  function getNodeTitle {
    
    local selectNode="${1}"

    local replaceFrom="$(echo ${indexlist[(( selectNode - 1 ))]} | cut -d: -f 2)"

    echo "${replaceFrom##*.}"

  }
}

: "選択グループ範囲取得" && {
  ##############################################################################
  # 選択ノードの所属するグループの範囲(ノード番号)を取得する
  # 引数1:対象ノード番号
  # 引数2:出力する行の種類　1:開始行番号を出力/9:終了行番号を出力
  # 戻り値:開始行番号,終了行番号
  ##############################################################################
  function getNodeNoInGroup {
    local selectNodeNo="${1}"
    local mode="${2}"
    local selectNoedDepth="$( getDepth ${selectNodeNo} )"

    startnodeSelectGroup="${selectNodeNo}"
    endnodeSelectGroup="${maxCnt}"

    for i in $( seq "$(( ${selectNodeNo} + 1 ))" "${maxCnt}") ;
    do
      depthCheck="$( getDepth ${i} )"
      if [[ ${depthCheck} -le ${selectNoedDepth} ]] ; then
        endnodeSelectGroup="$(( ${i} - 1 ))"
        break
      fi
    done

    case "${mode}" in
      '') echo "${startnodeSelectGroup} ${endnodeSelectGroup}" ;;
      1) echo  "${startnodeSelectGroup}" ;;
      9) echo  "${endnodeSelectGroup}" ;;
      *) echo  "${startnodeSelectGroup} ${endnodeSelectGroup}" ;;
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
    tree 1 "${maxCnt}"
  }

  ##############################################################################
  # 対象グループをフォーカス表示する
  # f:通常フォーカス表示
  # fl:開始行番号付きフォーカス表示
  # fa:開始終了行番号深さ付きフォーカス表示
  # グループ(開始ノードと終了ノード)を指定してツリービューを呼び出すラッパー
  ##############################################################################
  function focusMode {

    local startnodeSelectGroup="$(getNodeNoInGroup ${indexNo} 1 )"
    local endnodeSelectGroup="$(getNodeNoInGroup ${indexNo} 9 )"
    tree "${startnodeSelectGroup}" "${endnodeSelectGroup}"
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

    local startnodeSelectGroup="${1}"
    local endnodeSelectGroup="${2}"

    echo "【$(basename ${inputFile})】★ フォーカス表示中"
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

    seq "${startnodeSelectGroup}" "${endnodeSelectGroup}" | {
      while read -r cnt ; do
      startLine="$( getLineNo ${cnt} 1 )"
      endLine="$(   getLineNo ${cnt} 9 )"
      depth="$( getDepth ${cnt} )"


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
      done
    }

    echo '❓️引数なしでhelp参照'
    exit 0
   
  }
}

: "ノード削除・編集・閲覧コマンド" && {
  ##############################################################################
  # d:対象のノードを削除する
  # e:対象のノードを編集する
  # v:対象のノードを閲覧する
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function singleNodeOperations {

    startLine="$( getLineNo $(( ${indexNo} - 1 )) 1 )"
    endLine="$(   getLineNo     ${indexNo}        1 )"

    if [[ ${indexNo} -eq 1 ]]; then
      cat "${inputFile}" | { sed -n "1, $((endLine-1))p" > "${tmpfileB}"; cat >/dev/null;}
      tail -n +$((endLine)) "${inputFile}" > "${tmpfileF}"
    else
      if [[ ${indexNo} -eq $maxCnt ]]; then
        cat "${inputFile}" | { head -n "$((startLine-1))" > "${tmpfileH}"; cat >/dev/null;}
        cat "${inputFile}" | { tail -n +$((startLine))  > "${tmpfileB}"; cat >/dev/null;}
        echo '' > "${tmpfileF}"
      else
        cat "${inputFile}" | { head -n "$((startLine-1))" > "${tmpfileH}"; cat >/dev/null;}
        cat "${inputFile}" | { sed -n "$((startLine)), $((endLine-1))p" > "${tmpfileB}"; cat >/dev/null;} 
        tail -n +$((endLine)) "${inputFile}" > "${tmpfileF}"
      fi
    fi

    case "${action}" in
      9)  "${selected_editor}" "${tmpfileB}"
            wait
            sed -i -e '$a\' "${tmpfileB}" #編集の結果末尾に改行がない場合'
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
  }
}

: "ノード挿入コマンド" && {
  ##############################################################################
  # 対象のノードの下に新しいノードを挿入する
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function insertNode {
    
    #ノードの検出
    detectNode

    nlString='New Node'
    endlinePreviousNode="$( getLineNo $(( ${indexNo} -1 )) 9 )"
    startlineNextNode="$(   getLineNo ${indexNo} 1 )"

    depth="$( getDepth ${indexNo} )"
    dots="$(seq ${depth} | while read -r line; do printf '.'; done)"

    echo "${dots}${nlString}" > "${tmpfileB}"
    cat "${inputFile}" | { head -n "${endlinePreviousNode}" > "${tmpfileH}"; cat >/dev/null;}

    if [[ ${indexNo} -eq ${maxCnt} ]] ;then
      awk 1 "${inputFile}" "${tmpfileB}" > "${tmpfile1}"
      cat "${tmpfile1}" > "${inputFile}"

    else
      cat "${inputFile}" | { tail -n +${startlineNextNode}  > "${tmpfileF}"; cat >/dev/null;}
      cat "${tmpfileH}" "${tmpfileB}" "${tmpfileF}" > "${inputFile}"
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
            exit 1
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
    case "${char2}" in
      'u')  indexTargetNode="$(( ${indexNo} -1 ))"
            indexSelectNode="$(( ${indexNo}    ))"
            indexNextNode="$((   ${indexNo} +1 ))"

            endlinePreviousNode="$(( $( getLineNo ${indexTargetNode} 1 ) - 1 ))"
            startlineTargetNode="$(     getLineNo ${indexTargetNode} 1 )"
            endlineTargetNode="$(       getLineNo ${indexTargetNode} 9 )"
            startlineSelectNode="$( getLineNo ${indexSelectNode} 1 )"
            endlineSelectNode="$(   getLineNo ${indexSelectNode} 1 )"

            if [[ ${indexNo} -eq ${maxCnt} ]] ; then
              startlineNextNode=''
            else
              startlineNextNode="$( getLineNo ${indexNextNode} 1 )"
            fi
            
            (
              cat "${inputFile}" | { head -n "${endlinePreviousNode}" > "${tmpfileH}"; cat >/dev/null;}
              cat "${inputFile}" | { sed -sn "${startlineTargetNode},${endlineTargetNode}p" > "${tmpfileT}"; cat >/dev/null;}
              cat "${inputFile}" | { sed -sn "${startlineSelectNode},${endlineSelectNode}p" > "${tmpfileB}"; cat >/dev/null;}
              if [[ ! "${startlineNextNode}" = '' ]] ; then 
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

            ;;

      'd')  indexPreviousNode="$(( ${indexNo} -1 ))"
            indexTargetNode="$((   ${indexNo} +1 ))"
            indexSelectNode="$((   ${indexNo}    ))"
            indexNextNode="$((     ${indexNo} +2 ))"
            
            endlinePreviousNode="$( getLineNo ${indexPreviousNode} 9 )"
            startlineSelectNode="$( getLineNo ${indexSelectNode}   1 )"
            endlineSelectNode="$(   getLineNo ${indexSelectNode}   9 )"
            startlineTargetNode="$( getLineNo ${indexTargetNode}   1 )"

            if [[ ${indexNo} -eq ${maxCnt} ]] ; then
              endlineTargetNode="$(cat "${inputFile}" | wc -l )"
            else
              endlineTargetNode="$( getLineNo ${indexTargetNode} 9 )"
              startlineNextNode="$( getLineNo ${indexNextNode}   1 )"
            fi
            (
              if [[ ${indexNo} -eq 1 ]] ; then
                echo '' > "${tmpfileH}"
              else
                cat "${inputFile}" | { head -n "${endlinePreviousNode}" > "${tmpfileH}"; cat >/dev/null;}
              fi
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
            ;;

      *)    echo 'err'
            exit 1
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

    local startnodeSelectGroup="$( getNodeNoInGroup ${indexNo} 1 )"
    local endnodeSelectGroup="$(   getNodeNoInGroup ${indexNo} 9 )"

    case "${char3}" in
      'l')  for i in $(seq "${startnodeSelectGroup}" "${endnodeSelectGroup}") ;
            do
              tgtLine="$( getLineNo ${i} 1 )"
              sed -i -e "${tgtLine} s/^\.\./\./g" "${inputFile}"
            done
            ;;
      'r')  for i in $(seq "${startnodeSelectGroup}" "${endnodeSelectGroup}") ;
            do
              tgtLine="$( getLineNo ${i} 1 )"
              sed -i -e "${tgtLine} s/^\./\.\./g" "${inputFile}"
            done
            ;;
      *)    echo 'err'
            read -s -n 1 c
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
    #ノードの検出

    ##対象ノードと同じかそれよりも浅いノードが登場するまでに含まれる
    ##対象ノードよりもノード番号が大きい全てのノードを、対象グループとする
    : "対象グループ情報を取得" && {

      #ノード番号開始と終了
      ##対象グループ開始ノードは、起動時に指定した対象ノード
      startnodeSelectGroup="$(( ${indexNo} ))"

      ##対象グループ終了ノードは、
      ##対象グループ開始ノードと同じ深さかそれより浅いノードが登場するまでノードを下っていき
      ##その範囲に含まれるノードすべて
      for i in $(seq "${indexNo}" "${maxCnt}") ;
      do
        depthCheck="$( getDepth ${i} )"
        if [[ ${depthCheck} -le ${depth} ]] ; then
          endnodeSelectGroup="${i}"
          break
        fi
      done

      #対象グループ開始ノードの開始行番号を取得し、対象グループ開始行数とする
      startLineTargetGroup="$(getLineNo ${startnodeSelectGroup} 1 )"

      #対象グループ終了ノードの終了行番号を取得し、対象グループ終了行数とする
      endLineTargetGroup="$(getLineNo ${endnodeSelectGroup} 9 )"

      echo "${startLineTargetGroup}---${endLineTargetGroup}"

    }

    : "目標グループ情報を取得" && {
      #上移動の場合
      ##かつ対象ノードが一番上の場合
      :
    }

    exit 1

    #動作の想定
    #上移動の場合
    ##対象ノードと同じかそれよりも浅いノードが登場するまでに含まれる
    ##対象ノードよりもノード番号が小さい全てのノードを、目標グループとする
    ###目標グループが存在しない場合、移動先なしエラーとする

    ##目標グループよりも上の行は全てヘッダーグループとする
    ###ただし、目標グループよりも上の行がない場合、ヘッダーグループは空とする
    ##対象グループよりも下の行は全てフッターグループである
    ###ただし、対象グループよりも下の行がない場合、フッターグループは空とする

    #下移動の場合
    ##対象グループの次のノードから、それと同じかそれよりも浅いノードが登場するまでに含まれる
    ##それよりもノード番号が大きい全てのノードを、目標グループとする
    ###目標グループが存在しない場合、移動先なしエラーとする

    ##対象グループよりも上の行は全てヘッダーグループとする
    ###ただし、ヘッダーグループがない場合、ヘッダーグループは空とする
    ##目標グループよりも下の行は全てフッターグループとする
    ###目標グループより下の行がない場合、フッターグループは空とする
    
    


    startlineSelectGroup=$(echo "${indexlist[ ${startnodeSelectGroup} ]}" | cut -d':' -f 1)
    if [[ ${endnodeSelectGroup} -ne ${maxCnt} ]] ; then
      endlineSelectGroup=$(( $(echo "${indexlist[ ${endnodeSelectGroup} ]}" | cut -d':' -f 1) - 1 ))
    else
      endlineSelectGroup=$(cat ${inputFile} | wc -l)
    fi

    case "${char3}" in
      'u')  indexCheck=$(( ${indexNo} - 2 ))
            depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
            i=2
            while [[ ${depth} -ne ${depthCheck} ]] && [[ ${indexCheck} -gt 0 ]] ;
            do
              indexCheck=$(( ${indexNo} - ${i} ))
              depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
              i=$(($i+1))
            done
            if [[ ${indexCheck} -eq  0 ]] ; then
              echo '移動可能なノードがありません'
              read -s -n 1 c
              bash "${0}" "${inputFile}" 't'
              exit 0
            fi

            startlineTargetGroup=$(echo "${indexlistN[ ${indexCheck} ]}"| cut -d':' -f 1)
            endlineTargetGroup=$(echo $(( $( echo "${indexlistN[ $((${indexNo}-1)) ]}"| cut -d':' -f 1 ) - 1 ))) 

            startlineHeadGroup='1'
            endlineHeadGroup=$(( ${startlineTargetGroup} - 1 ))

            if [[ ${endnodeSelectGroup} -ne ${maxCnt} ]] ; then
              startlineFooterGroup=$(( ${endlineSelectGroup} + 1))
              endlineFooterGroup=$( cat "${inputFile}" | wc -l  )
            fi

            echo "${startlineHeadGroup}-${endlineHeadGroup}"
            echo "${startlineTargetGroup}-${endlineTargetGroup}"
            echo "${startlineSelectGroup}-${endlineSelectGroup}"
            echo "${startlineFooterGroup}-${endlineFooterGroup}"
            exit 1

            (
              cat "${inputFile}" | { head -n "${endlineHeadGroup}" > "${tmpfileH}"; cat >/dev/null;}
              cat "${inputFile}" | { sed -sn "${startlineSelectGroup},${endlineSelectGroup}p" > "${tmpfileT}"; cat >/dev/null;} 
              cat "${inputFile}" | { sed -sn "${startlineTargetGroup},${endlineTargetGroup}p" > "${tmpfileB}"; cat >/dev/null;}

              if [[ ${endnodeSelectGroup} -ne ${maxCnt} ]] ; then
                tail -n +"${startlineFooterGroup}" "${inputFile}" > "${tmpfileF}"
              fi
              wait
            )
            (
              cat "${tmpfileH}" "${tmpfileT}" > "${tmpfile1}"
              if [[ ${endnodeSelectGroup} -ne ${maxCnt} ]] ; then
                cat "${tmpfileB}" "${tmpfileF}" > "${tmpfile2}"
              else
                cat "${tmpfileB}" > "${tmpfile2}"
              fi
              wait
            )
            cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"
      
            ;;
      'd')  indexCheck=$(( ${indexNo} + 1 ))
            depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
            i=0
            while [[ ${depth} -ne ${depthCheck} ]] && [[ ${indexCheck} -gt 0 ]] ;
            do
              i=$(($i+1))
              indexCheck=$(( ${indexNo} + ${i} ))
              depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
            done
            if [[ ${indexCheck} -eq  0 ]] ; then
              echo '移動可能なノードがありません'
              read -s -n 1 c
              bash "${0}" "${inputFile}" 't'
              exit 0
            fi
            indexCheck=$(($i+indexCheck))

            i=0
            while [[ ${depth} -ne ${depthCheck} ]] && [[ ${indexCheck} -gt 0 ]] ;
            do
              i=$(($i+1))
              indexCheck=$(( ${indexNo} + ${i} ))
              depthCheck=$(echo "${indexlistN[ ${indexCheck} ]}" | cut -d':' -f 2 | grep -oP '^\.+' | grep -o '.' | wc -l)
            done


            startlineTargetGroup=$(echo "${indexlistN[ $((${indexCheck})) ]}"| cut -d':' -f 1)
            endlineTargetGroup=$(echo $(( $( echo "${indexlistN[ $((${indexCheck} + 1 )) ]}"| cut -d':' -f 1 ) - 1 )))


            startlineHeadGroup='1'
            endlineHeadGroup=$(( ${startlineSelectGroup} - 1 ))

            startlineFooterGroup=$(( ${endlineTargetGroup} + 1))
            endlineFooterGroup=$( cat "${inputFile}" | wc -l  )

            echo "${startlineHeadGroup}-${endlineHeadGroup}"
            echo "${startlineSelectGroup}-${endlineSelectGroup}"
            echo "${startlineTargetGroup}-${endlineTargetGroup}"
            echo "${startlineFooterGroup}-${endlineFooterGroup}"

            (
              cat "${inputFile}" | { head -n "${endlineHeadGroup}" > "${tmpfileH}"; cat >/dev/null;}
              cat "${inputFile}" | { sed -sn "${startlineTargetGroup},${endlineTargetGroup}p" > "${tmpfileT}"; cat >/dev/null;} 
              cat "${inputFile}" | { sed -sn "${startlineSelectGroup},${endlineSelectGroup}p" > "${tmpfileB}"; cat >/dev/null;}
              tail -n +"${startlineFooterGroup}" "${inputFile}" > "${tmpfileF}"
              wait
            )
            (
              cat "${tmpfileH}" "${tmpfileT}" > "${tmpfile1}"
              cat "${tmpfileB}" "${tmpfileF}" > "${tmpfile2}"
              wait
            )
            cat "${tmpfile1}" "${tmpfile2}" > "${inputFile}"
            ;;
      *)    echo 'err'
            read -s -n 1 c
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
    local MAX_BACKUP_COUNT="${2}"
  
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
      bash "${0}" "${inputFile}" 't'
      return 0
    fi

    #動作指定を省略して段落を指定した場合、編集に読み替え
    if [[ ${action} =~ ^[0-9]+$ ]] && [[ ${#indexNo} = 0 ]] ; then
      bash "${0}" "${inputFile}" 9 "${action}"
      return 0
    fi

    if [[ -f ${inputFile} ]] && [[ ${#action} = 0 ]] ; then
      bash "${0}" "${inputFile}" 't'
      return 0
    fi

    ######################################
    #バックアップ作成
    ######################################
    makeBackupActionList=(9 'd' 'i' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd')
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

    #対象ファイルの存在チェック
    if [[ ! -f ${inputFile} ]] ; then
      echo "${inputFile} なんてファイルないです"
      read -s -n 1 c
      return 1
    fi

    #動作指定のチェック
    allowActionList=('h' 9 'd' 'i' 't' 'tl' 'ta' 'f' 'fl' 'fa' 'v' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -ne 0 ]] ; then
      echo '引数2:無効なアクションです'
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=(9 'd' 'i' 'f' 'fl' 'fa' 'v' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd')
    printf '%s\n' "${allowActionList[@]}" | grep -qx "${action}"
    if [[ ${?} -eq 0 ]] ; then
      if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxCnt} ]] ; then
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
    if [[ ${?} -eq 0 ]] && [[ ${indexNo} -ge ${maxCnt} ]] ; then
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
    tmpfileH="$(mktemp)"
    tmpfileB="$(mktemp)"
    tmpfileT="$(mktemp)"
    tmpfileF="$(mktemp)"
    tmpfile1="$(mktemp)"
    tmpfile2="$(mktemp)"

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
    indexNo="${3}"

    myInit                      # 初期処理

    #パラメータチェック
    parameterCheck
    if [[ ${?} -ne 0 ]] ; then 
      exit 1
    fi

    makeBackup "${inputFile}" 3 # バックアップ作成。今のところ3世代固定
    makeTmpfile                 # 一時ファイルを作成
    #displayHelp                 # ヘルプ表示

    char1="${action:0:1}"
    char2="${action:1:1}"
    char3="${action:2:1}"

    clear

    case "${char1}" in
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
      'g')  case "${char3}" in 
              [ud]) swapGroup
                    ;;
              [lr]) slideGroup
                    ;;
              *)  echo 'err'
                  ;;
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
 
