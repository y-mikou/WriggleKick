#!/bin/bash

: "ユーザー設定領域" && {
  ##############################################################################
  #エディタ、ビューワーの指定
  ##############################################################################
  selected_editor='selected_editor'
                  #^^^^^^^^^^^^^^^ここにお好みのエディター呼び出しコマンドを設定してください
  selected_viewer='selected_viewer'
                  #^^^^^^^^^^^^^^^ここにお好みのビューワー呼び出しコマンドを設定してください
                  #ビューワとしてlessなどの編集モードを持つものを指定しても、閲覧のみが可能です。
                  #当ツールのv系コマンド(ノードの編集なし閲覧)でのファイルの編集内容は反映されません。

  ##############################################################################
  #編集モードで開く際の拡張行数
  ##############################################################################
  edit_mode_extend_lines=0 #0で拡張なし
}

: "ヘルプ表示" && {
  ##############################################################################
  # 引数:なし、もしくはコマンド
  ##############################################################################
  function commandList {
    echo '■Simple Outliner[Wriggle Kick]'
    echo '>help'
    echo '[Wriggle Kick]はしょぼいアウトライナー(日本語用)です。'
    echo '#でノードを示す構造化テキストファイルのアウトラインを対象とし、'
    echo '以下引数での動作指定に従いアウトラインを表示し、構造を変更したり、ノードを削除や追加したり、ノードに属性を付与したりします。'
    echo '編集を指示した場合は指定したテキストエディタへ対象のノードを流し込むことでノードを指定した編集を可能にします。'
    echo '編集を加えてテキストエディタを終了すると、元のファイルにもその変更を適用します。'
    echo '動作指定ごとの説明は、対象ファイルを指定せずに'
    echo 'bash wrigglekick h [command]'
    echo 'で確認してください。'
    echo '　引数1:対象File'
    echo '　引数2:動作指定'
    echo '　　　　　t.....ツリービュー(省略可)　hオプション:不可視フラグonのノードを非表示'
    echo '　　　　　tl....行番号付きツリービュー　hオプション:不可視フラグonのノードを非表示'
    echo '　　　　　ta...行番号範囲深さ付きツリービュー　hオプション:不可視フラグonのノードを非表示'
    echo '　　　　　f.....フォーカスビュー　hオプション:不可視フラグonのノードを非表示'
    echo '　　　　　fl....行番号付きフォーカスビュー　hオプション:不可視フラグonのノードを非表示'
    echo '　　　　　fa...行番号範囲深さ付きフォーカスビュー　hオプション:不可視フラグonのノードを非表示'
    echo '　　　　　v.....対象ノードの閲覧'
    echo '　　　　　gv....対象ノードの配下ノードを横断的に閲覧'
    echo '　　　　　e.....対象ノードの編集'
    echo '　　　　　d.....対象ノードの削除'
    echo '　　　　　gd....対象ノードの削除'
    echo '　　　　　h.....対象ノードに不可視フラグを設定(1:不可視/0:可視)'
    echo '　　　　　gh....対象ノードの配下ノードにまとめて不可視フラグを設定(1:不可視/0:可視)'
    echo '　　　　　i.....対象ノードの下に新規ノード挿入。追加引数としてノード名'
    echo '　　　　　ie....対象ノードの下に新規ノード挿入、即編集モードへ。追加引数としてノード名'
    echo '　　　　　mu....対象ノードひとつを上へ移動'
    echo '　　　　　md....対象ノードひとつを下へ移動'
    echo '　　　　　ml....対象ノードひとつを左へ移動(浅くする)'
    echo '　　　　　mr....対象ノードひとつを右へ移動(深くする)'
    echo '　　　　　gmu...自分の配下ノードを引き連れて上へ移動'
    echo '　　　　　gmd...自分の配下ノードを引き連れて下へ移動'
    echo '　　　　　gml...自分の配下ノードを引き連れて左へ移動(浅くする)'
    echo '　　　　　gmr...自分の配下ノードを引き連れて右へ移動(深くする)'
    echo '　　　　　j.....指定ノードを、下のノードと結合'
    echo '　　　　　gj....自分の配下ノードを、自分に統合'
    echo '　　　　　k.....指定ノードの済/未マークを切り替える'
    echo '　　　　　gk....自分の配下ノードにまとめて済/未フラグを設定(1:済/0:未)'
    echo '　　　　　gc....自分の配下ノードを含んだ文字数を通知する'
    echo '　　　　　s.....指定ノードに表示シンボルを設定する。追加引数でシンボルを指定(1文字)'
    echo '　　　　　o.....自分の配下ノードを含んだ範囲を別ファイル出力する。追加引数で出力ファイル名'
    echo '　　　　　数字...対象ノードを編集(eと引数3を省略)'
    echo '　引数3:動作対象ノード番号/ノード指定の無い動作ではオプション'
    echo '　引数4:動作指定ごとに必要なオプション'
  }

  function help-t {
    clear
    echo '■t系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] t/tl/ta'
    echo ''
    echo 't系コマンド([t]ree)には、他にtl([t]ree [l]ine)、ta([t]ree [a]ll)のファミリーがあります。'
    echo ''
    echo 't系コマンドファミリーはいずれも対象ファイル(実際に起動する際には第1引数となる)の'
    echo 'ツリー構造を表示するコマンドです。ファミリー内のコマンドごとに表示される情報が異なります。'
    echo ''
    echo 'hコマンドによって不可視属性が設定されたノードは、更にhオプションを渡すことでノードを非表示にできます。'
    echo 'fコマンドとあわせて、編集時の視覚ノイズ低減にご利用ください。'
    echo ''
    echo '+--------+--------+------+------+----+------+------+------+------+--------+--------+'
    echo '|コマンド|node番号|開始行|終了行|深さ|文字数|済未済|可視性|ツリー|属性記号|タイトル|'
    echo '+--------+--------+------+------+----+------+------+------+------+--------+--------+'
    echo '|    t   |   ＊   |      |      |    |      |  ＊  |      |  ＊  |   ＊   |   ＊   |'
    echo '|   tl   |   ＊   |  ＊  |      |    |  ＊  |  ＊  |      |  ＊  |   ＊   |   ＊   |'
    echo '|   ta   |   ＊   |  ＊  |  ＊  | ＊ |  ＊  |  ＊  |  ＊  |  ＊  |   ＊   |   ＊   |'
    echo '+--------+--------+------+------+----+------+------+------+------+--------+--------+'
  }
  function help-f {
    clear
    echo '■f系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] f/fl/fa'
    echo ''
    echo 'f系コマンド([f]orcus)には、他にfl([f]orcus [l]ine)、fa([f]orcus [a]ll)のファミリーがあります。'
    echo ''
    echo 'f系コマンドファミリーはいずれも対象ファイル(実際に起動する際には第1引数となる)の'
    echo '指定したノード番号を先頭とするグループ内に絞ってツリー構造を表示するコマンドです。'
    echo ''
    echo 'tコマンドとfコマンドの違いは、表示するノードをグループに絞っているかどうかだけです。'
    echo ''
    echo 'hコマンドによって不可視属性が設定されたノードは、更にhオプションを渡すことでノードを非表示にできます。'
    echo '編集時の視覚ノイズ低減にご利用ください。'
    echo ''
    echo '※グループとは、'
    echo '指定したノードからノード番号を下っていき'
    echo '最初に「基準と同じか基準より浅いノード」が発見されたときに、'
    echo '指定したノード〜発見されたノードの一つ手前までの範囲を指します。'
    echo '最後尾のノードに到達しても基準と同じかそれより浅いノードが見つからなかった場合は'
    echo '指定したノード〜最後尾のノードをグループとします。'
    echo ''
    echo 'ex:'
    echo '1 深さ1'
    echo '2 └深さ2'
    echo '3 └深さ2'
    echo '4   └深さ3'    
    echo '5 深さ1'
    echo '6 └深さ2'
    echo ''
    echo '→指定ノード=3のとき、グループは3〜4'
    echo '→指定ノード=2のとき、グループは2だけ'
    echo '→指定ノード=1のとき、グループは1〜4'
    echo ''
    echo 'ファミリーのコマンドごとに表示される情報が異なります。'
    echo '(基本的にtコマンドと同じ情報が参照できます。)'
    echo ''
    echo '+--------+--------+------+------+----+------+------+------+------+--------+--------+'
    echo '|コマンド|node番号|開始行|終了行|深さ|文字数|済未済|可視性|ツリー|属性記号|タイトル|'
    echo '+--------+--------+------+------+----+------+------+------+------+--------+--------+'
    echo '|    f   |   ＊   |      |      |    |      |  ＊  |      |  ＊  |   ＊   |   ＊   |'
    echo '|   fl   |   ＊   |  ＊  |      |    |  ＊  |  ＊  |      |  ＊  |   ＊   |   ＊   |'
    echo '|   fa   |   ＊   |  ＊  |  ＊  | ＊ |  ＊  |  ＊  |  ＊  |  ＊  |   ＊   |   ＊   |'
    echo '+--------+--------+------+------+----+------+------+------+------+--------+--------+'
  }
  function help-v {
    clear
    echo '■v系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] v/gv [対象ノード番号]'
    echo ''
    echo 'v系コマンド([v]iew)には、他にgv([g]roup [v]iew)のファミリーがあります。'
    echo ''
    echo 'v系コマンドは編集を行わない前提で、対象ファイルの指定ノードを閲覧します。'
    echo '閲覧は、当スクリプトが稼働する環境にあるファイルビューアを呼び出す形で実現されます。'
    echo '当スクリプト冒頭の変数「selected_viewer」の値を、任意のビューア呼び出しコマンド(例えばlessなど)に置き換えてください。'
    echo '指定がない場合、less > more > view > cat の優先順で存在するものが使用されます。'
    echo 'ビューワとしてnanoのようなエディタを指定することも可能ですが、正常動作は保証しません。'
    echo ''
    echo 'gvコマンドの場合、指定ノードを先頭としたグループを横断的に閲覧します。'
    echo ''
    echo '※グループとは、'
    echo '指定したノードからノード番号を下っていき'
    echo '最初に「基準と同じか基準より浅いノード」が発見されたときに、'
    echo '指定したノード〜発見されたノードの一つ手前までの範囲を指します。'
    echo '最後尾のノードに到達しても基準と同じかそれより浅いノードが見つからなかった場合は'
    echo '指定したノード〜最後尾のノードをグループとします。'
    echo ''
    echo 'ex:'
    echo '1 深さ1'
    echo '2 └深さ2'
    echo '3 └深さ2'
    echo '4   └深さ3'    
    echo '5 深さ1'
    echo '6 └深さ2'
    echo ''
    echo '→指定ノード=3のとき、グループは3〜4'
    echo '→指定ノード=2のとき、グループは2だけ'
    echo '→指定ノード=1のとき、グループは1〜4'
  }
  function help-m {
    clear
    echo '■m系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] mu/ml/md/mr [対象ノード番号]'
    echo ''
    echo 'm系コマンド([m]ove)には、mu([m]ove [u]p)、md([m]ove [d]own)、ml([m]ove [l]eft)、mr([m]ove [r]ight)のファミリーがあります。'
    echo ''
    echo 'それぞれ、指定のノードの位置を変更します。'
    echo ''
    echo 'ml([m]ove [l]eft)コマンドは、指定のノードを、一つ左に移動します。つまり、深さを一つ浅くします。'
    echo 'mr([m]ove [r]ight)コマンドは、指定のノードを、一つ右に移動します。つまり、深さを一つ深くします。'
    echo 'mu([m]ove [u]p)コマンドは、指定のノードを、一つ上に移動します。つまり、一つ上のノードと入れ替えます。'
    echo 'md([m]ove [d]own)コマンドは、指定のノードを、一つ下に移動します。つまり、一つ下のノードと入れ替えます。'
    echo ''
    echo '※この移動をノード一つではなく、グループごと行うgmコマンドファミリーも存在します。'
  }
  function help-gm {
    clear
    echo '■gm系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] gmu/gml/gmd/gmr [対象ノード番号]'
    echo ''
    echo 'gm系コマンド([g]roup [m]ove)には、'
    echo 'gmu([g]roup [m]ove [u]p)、gmd([g]roup[m]ove [d]own)、gml([g]roup [m]ove [l]eft)、gmr([g]roup [m]ove [r]ight)'
    echo 'のファミリーがあります。'
    echo ''
    echo 'それぞれ、指定のノードを先頭としたグループごと、位置を変更します。'
    echo ''
    echo 'gml([g]roup [m]ove [l]eft)コマンドは、'
    echo '指定のノードを先頭としたグループ全体を、一つ左に移動します。つまり、深さを一つ浅くします。'
    echo 'gmr([g]roup [m]ove [r]ight)コマンドは、'
    echo '指定のノードを先頭としたグループ全体を、一つ右に移動します。つまり、深さを一つ深くします。'
    echo 'gmu([g]roup [m]ove [u]p)コマンドは、'
    echo '指定のノード先頭としたグループ全体を、一つ上にある、同じ深さのグループ全体と入れ替えます。'
    echo 'gmd([g]roup [m]ove [d]own)コマンドは、'
    echo '指定のノード先頭としたグループ全体を、一つ下にある、同じ深さのグループ全体と入れ替えます。'
    echo ''
    echo '※グループとは、'
    echo '指定したノードからノード番号を下っていき'
    echo '最初に「基準と同じか基準より浅いノード」が発見されたときに、'
    echo '指定したノード〜発見されたノードの一つ手前までの範囲を指します。'
    echo '最後尾のノードに到達しても基準と同じかそれより浅いノードが見つからなかった場合は'
    echo '指定したノード〜最後尾のノードをグループとします。'
    echo ''
    echo 'ex:'
    echo '1 深さ1'
    echo '2 └深さ2'
    echo '3 └深さ2'
    echo '4   └深さ3'    
    echo '5 深さ1'
    echo '6 └深さ2'
    echo ''
    echo 'gmd 1 としたとき、'
    echo 'ノード番号1と同じ深さを持つ次のノードを先頭としたグループとグループごと入れ替わるため、実行後は'
    echo ''
    echo '1 深さ1'
    echo '2 └深さ2'
    echo '3 深さ1'
    echo '4 └深さ2'
    echo '5 └深さ2'
    echo '6   └深さ3'
    echo ''
    echo 'となります'
    echo ''
    echo '上下に同じ深さの別グループが存在しなかった場合、移動されずに終了します。'
    echo '先頭ノードがすでに深さ1のときには、gmlコマンドは処理されずに終了します。'
    echo '深さには制限を設けていないのでgmrコマンドは必ず移動しますが、あまり深すぎる場合の動作の保証はしません。'
  }
  function help-d {
    clear
    echo '■d系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] d/gd [対象ノード番号]'
    echo ''
    echo 'd系コマンド([d]elete)には、gd([g]roup [d]elete)のファミリーがあります。'
    echo ''
    echo 'dコマンドは、指定したノードを削除します。'
    echo ''
    echo 'gdコマンドは、'
    echo '指定のノードを先頭としたグループ全体を、一気に削除します。'
    echo ''
    echo '※グループとは、'
    echo '指定したノードからノード番号を下っていき'
    echo '最初に「基準と同じか基準より浅いノード」が発見されたときに、'
    echo '指定したノード〜発見されたノードの一つ手前までの範囲を指します。'
    echo '最後尾のノードに到達しても基準と同じかそれより浅いノードが見つからなかった場合は'
    echo '指定したノード〜最後尾のノードをグループとします。'
    echo ''
    echo 'ex:'
    echo '1 深さ1'
    echo '2 └深さ2'
    echo '3 └深さ2'
    echo '4   └深さ3'    
    echo '5 深さ1'
    echo '6 └深さ2'
    echo ''
    echo 'gd 3 としたとき、実行後は'
    echo ''
    echo '1 深さ1'
    echo '2 └深さ2'
    echo '3 深さ1'
    echo '4 └深さ2'
    echo ''
    echo 'となります。'
  }
  function help-j {
    clear
    echo '■j系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] j [対象ノード番号]'
    echo ''
    echo 'j系コマンド([j]oin)には、今のところ他のファミリーはありません。'
    echo ''
    echo 'jコマンドは、指定したノードとそのひとつ下のノードを結合して、一つのノードにします。'
    echo 'ノードの名称や深さは、指定したノードのものになります。'
  }
  function help-k {
    clear
    echo '■k系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] k/gk [対象ノード番号]'
    echo ''
    echo 'k系コマンド(chec[k])には、他にgkコマンド([g]roup chec[k])があります。'
    echo ''
    echo 'kコマンドは、指定したノードの完了フラグのオンオフを切り替えます'
    echo '現在未完了状態の場合は完了に、完了状態の場合は未完了になります。'
    echo ''
    echo 'gkコマンドは、指定したグループ全体の完了/未了を設定します。'
    echo 'kコマンドと異なり、切り替えではなく、追加引数として0を与えると未了、1を与えると完了になり、'
    echo 'グループ内のノードすべてを完了、または未了にします。'
    echo ''
    echo '※グループとは、'
    echo '指定したノードからノード番号を下っていき'
    echo '最初に「基準と同じか基準より浅いノード」が発見されたときに、'
    echo '指定したノード〜発見されたノードの一つ手前までの範囲を指します。'
    echo '最後尾のノードに到達しても基準と同じかそれより浅いノードが見つからなかった場合は'
    echo '指定したノード〜最後尾のノードをグループとします。'
  }
  function help-gc {
    clear
    echo '■gc系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] gc [対象ノード番号]'
    echo ''
    echo 'gc系コマンド([g]roup [c]ount)には、今のところ他のファミリーはありません。'
    echo ''
    echo 'gcコマンドは、指定したグループ内全体の文字数をカウントして表示します。'
    echo '但しこの文字数には、「//」で始まるコメントアウト行の文字数は合計されません。'
  }
  function help-h {
    clear
    echo '■h系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] h/gh [対象ノード番号] ([0/1])'
    echo ''
    echo 'h系コマンド([h]ide)には、他にgh([g]roup [h]ide)のファミリーがあります。'
    echo ''
    echo 'hコマンドは、指定のノードの不可視フラグを切り替えます。'
    echo '現在不可視の場合は可視に、可視の場合は不可視になります。'
    echo ''
    echo '不可視設定されたノードは、tコマンド、fコマンドにて、追加の引数hを指定した場合に表示されません'
    echo '(追加引数hを付与しない場合は何も影響を与えません)'
    echo ''    
    echo 'ghコマンドは、指定したグループ全体の可視/不可視を設定します。'
    echo 'hコマンドと異なり、切り替えではなく、追加引数として0を与えると可視、1を与えると不可視になり、'
    echo 'グループ内のノードすべてを可視、または不可視にします。'
  }
  function help-s {
    clear
    echo '■s系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] s [対象ノード番号] [任意の文字]'
    echo ''
    echo 's系コマンド([s]imbol)には、他にはファミリーはありません。'
    echo ''
    echo 'sコマンドは、指定のノードに任意の一文字の属性を付与します。'
    echo '属性を示す文字は絵文字を想定していますが、文字なら何でも良いです。'
    echo '属性を消す場合は、記号として空文字を指定してください。'
  }
  function help-i {
    clear
    echo '■i系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] i/ie [対象ノード番号] [ノードタイトル]'
    echo ''
    echo 'i系コマンド([i]nsert)には、他にie([i]nsert [e]dit)のファミリーがあります。'
    echo ''
    echo 'iコマンドは、指定のノードの後ろに新しいノードを追加します。'
    echo 'ノードタイトルの指定がない場合は、デフォルトのタイトルが付与されます。'
    echo ''
    echo 'ieコマンドは、指定のノードの後ろに新しいノードを追加した後、すぐに編集モードに入ります。'
    echo '※編集モードについては、eコマンドのヘルプを参照してください。'
    echo 'iコマンド同様、ノードタイトルの指定がない場合は、デフォルトのタイトルが付与されます。'
  }
  function help-o {
    clear
    echo '■o系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] o [出力ファイル名]'
    echo ''
    echo 'o系コマンド([o]utput)には、今のところ他のファミリーはありません。'
    echo ''
    echo 'oコマンドは、指定のノードを先頭とするグループを、出力ファイル名として別ファイルに保存します。'
    echo '※指定ノード単一ではありません。単一ノードだけを書き出す必要が出たら作ります'
    echo '出力ファイル名の指定がない場合は、指定したノードのタイトルが使用されます。'
    echo ''
    echo 'oコマンドで出力されるファイルには「//」で始まるコメントアウト行は含まれません。'
  }
  function help-e {
    clear
    echo '■e系コマンド ヘルプ'
    echo '書式: (bash) wrigglekick.sh [対象ファイル] (e) [対象ノード番号]'
    echo ''
    echo 'e系コマンド([v]iew)には、他にはファミリーはありません。'
    echo ''
    echo 'eコマンドのみ、コマンド自体を省略できます。即ち'
    echo '(bash) wrigglekick.sh [対象ファイル] [対象ノード番号]'
    echo 'と表記した場合には、それはeコマンドとみなします。'
    echo ''
    echo 'e系コマンドは対象ファイルの指定ノードをエディタへ渡します。'
    echo '当スクリプトでは、編集は稼働する環境にあるテキストエディタを呼び出す形で実現されます。'
    echo '当スクリプト冒頭の変数「selected_editor」の値を、任意のエディタ呼び出しコマンド(例えばviなど)に置き換えてください。'
    echo '指定がない場合、ms_edit > micro > nano > vi > ed の優先順で存在するものが使用されます。'
  }

  function displayHelp {
    local command="${1}"
    case "${command}" in
      't'|'tl'|'ta') help-t;;
      'f'|'fl'|'fa') help-f;;
      'v'|'gv') help-v;;
      'm'|'mu'|'md'|'ml'|'mr') help-m;;
      'gm'|'gmu'|'gmd'|'gml'|'gmr') help-gm;;
      'd'|'gd') help-d;;
      'j'|'gj') help-j;;
      'gc') help-gc;;
      'k') help-k;;
      'h') help-h;;
      's') help-s;;
      'i'|'ie') help-e;;
      'o') help-o;;
      'e') help-o;;
      *) commandList;;
    esac
  }

}

: "ノードタイトル行の分解" && {
  ##############################################################################
  # 外部プロセス呼び出しを高速化するための前処理群 
  ##############################################################################
  function parseMetadata {
    local input="${1}"
    local fieldNum="${2}"
    local metadata="${input#*\[}"
    metadata="${metadata%%\]*}"
    local IFS=','
    local -a fields=($metadata)
    echo "${fields[$((fieldNum-1))]}"
  }
  function arrayContains {
    local target="${1}"
    shift
    local element
    for element in "$@"; do
      [[ "${element}" == "${target}" ]] && return 0
    done
    return 1
  }
}

: "ノード検出" && {
  ##############################################################################
  # グローバル配列
  ##############################################################################
  declare -a nodeStartLines
  declare -a nodeEndLines
  declare -a nodeDepths
  declare -a nodeTitles
  declare -a nodeProgress
  declare -a nodeSymbols
  declare -a nodeHideFlags
  declare -a nodeCharCount

  ##############################################################################
  # ノード検出
  # 入力ファイルのノード構成を検出してグローバル設定する
  # 引数:なし(グローバル変数のみ参照)
  # グローバル変数設定:最大ノード数(maxNodeCnt)、各種配列
  ##############################################################################
  function detectNode {

    local entry
    local startLine
    local content      
    local endLine
    local title
    local progress
    local symbol
    local hideFlag
    local depth
    local nextEntry
    local nextStartLine

    readarray -t indexlist < <(grep -nP '^#+\s.+' ${inputFile})
    readarray -t fileLines < "${inputFile}"

    maxNodeCnt="${#indexlist[@]}"
    maxLineCnt="${#fileLines[@]}"

    nodeStartLines=()
    nodeEndLines=()
    nodeDepths=()
    nodeTitles=()
    nodeProgress=()
    nodeSymbols=()
    nodeHideFlags=()
    nodeCharCount=()

    for i in $(seq 1 ${maxNodeCnt}); do
      entry="${indexlist[$((i-1))]}"
      startLine="${entry%%:*}"
      content="${entry#*:}"      

      if [[ ${i} -ne ${maxNodeCnt} ]]; then
        nextEntry="${indexlist[${i}]}"
        nextStartLine="${nextEntry%%:*}"
        endLine=$(( ${nextStartLine} - 1 ))
      else
        endLine="${maxLineCnt}"
      fi
      
      depth="${content}"
      depth="${depth%%[^#]*}"
      depth="${#depth}"
      
      local withoutDepth="${content##*\# }"
      
      title="${withoutDepth%%\[*}"
      title="${title% }"
      
      progress="$(parseMetadata "${withoutDepth}" 1)"
      symbol="$(parseMetadata "${withoutDepth}" 2)"
      symbol="${symbol:0:1}" #1文字のみ
      hideFlag="$(parseMetadata "${withoutDepth}" 3)"
      hideFlag="${hideFlag:0:1}" #1文字のみ

      nodeStartLines+=("${startLine}")
      nodeEndLines+=("${endLine}")
      nodeDepths+=("${depth}")
      nodeTitles+=("${title}")
      nodeSymbols+=("${symbol:= }") #設定されていない場合には空白を一時的に設定
      nodeHideFlags+=("${hideFlag:=0}") #設定されていない場合には0を一時的に設定
      nodeProgress+=("${progress:=0}") #設定されていない場合には0を一時的に設定

      #taかtlの場合以外はスキップする

      local countActionList=('tl' 'ta' 'fl' 'fa')
      if arrayContains "${action}" "${countActionList[@]}"; then
        #次の行がすぐに次のノードタイトル行(純粋なタイトル行)の場合は0文字
        if [[ ${startLine} -eq ${endLine} ]] ; then
          charCount=0
        else
          local contentLines=""
          for ((lineNum=startLine; lineNum<=endLine; lineNum++)); do
            local line="${fileLines[$((lineNum-1))]}"
            if [[ ! "${line}" =~ ^# ]]; then
              contentLines+="${line}"
            fi
          done
          charCount="${#contentLines}"
        fi
        nodeCharCount+=("${charCount}")
      fi

    done
  }
}

: "シンボル系" && {
  ##############################################################################
  # 選択ノードの済マーク(☑️)と未済(⬜️)のマークを切り替える
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function switchProgress {
    
    local presentProgress="${nodeProgress[$((indexNo-1))]:=0}"
    presentProgress="${presentProgress:0:1}" #不正な文字が入っていた場合に1文字に削る

    if [[ ${presentProgress} -eq 0 ]] ; then
      modifiyProgress=1
    else
      modifiyProgress=0
    fi

    local targetLineNo="${nodeStartLines[$((indexNo-1))]}"

    local depth_markers="$( seq ${nodeDepths[$((indexNo-1))]} | while read -r line; do printf '#'; done )"
    local title="${nodeTitles[$((indexNo-1))]}"
    local symbol="${nodeSymbols[$((indexNo-1))]}"
    local hideFlag="${nodeHideFlags[$((indexNo-1))]}"

    modifiedTitlelineContent="${depth_markers} ${title} [${modifiyProgress},${symbol},${hideFlag}]"

    sed -i "${targetLineNo} c ${modifiedTitlelineContent}" "${inputFile}"

    displayLastTree
    exit 0
  }
  ##############################################################################
  # 配下ノードに完了フラグ(1:完了/0:未完了)を設定。指定シンボルを空にした場合は0(未完了)
  # 引数:なし(グローバルのみ)
  # 引数2:フラグ(1/0)
  ##############################################################################
  function setProgressGroup {
    local SelectGroupNodeFromTo="$(getNodeNoInGroup ${indexNo} '' )"
    local startNodeSelectGroup="$( echo ${SelectGroupNodeFromTo} | cut -d ' ' -f 1 )"
    local endNodeSelectGroup="$( echo ${SelectGroupNodeFromTo} | cut -d ' ' -f 2 )"

    local modifiedTitlelineContent=''
    local modifyFlag="${option:0:1}" #先頭1文字のみ

    local depth_markers=''
    local title=''
    local progress=''
    local symbol=''

    for i in $(seq "${startNodeSelectGroup}" "${endNodeSelectGroup}") ;
    do
      tgtLine="$( getLineNo ${i} 1 )"

      depth_markers="$( seq ${nodeDepths[$((i-1))]} | while read -r line; do printf '#'; done )"
      title="${nodeTitles[$((i-1))]}"
      # progress="${nodeProgress[$((i-1))]}"
      symbol="${nodeSymbols[$((i-1))]}"
      hideFlag="${nodeHideFlags[$((i-1))]}"

      modifiedTitlelineContent="${depth_markers} ${title} [${modifyFlag},${symbol},${hideFlag}]"
      sed -i "${tgtLine}c ${modifiedTitlelineContent}" "${inputFile}"
    done

    displayLastTree
    exit 0

  }

  ##############################################################################
  # 選択ノードにシンボルを設定。指定シンボルを空にした場合は削除
  # 引数:なし(グローバルのみ)
  # 引数2:設定するシンボル(1文字のみ)
  ##############################################################################
  function setSymbol {

    local modifySymbol="${option:0:1}" #1文字のみ

    local targetLineNo="${nodeStartLines[$((${indexNo}-1))]}"

    local depth_markers="$( seq ${nodeDepths[$((indexNo-1))]} | while read -r line; do printf '#'; done )"
    local title="${nodeTitles[$((indexNo-1))]}"
    local progress="${nodeProgress[$((indexNo-1))]}"
    local hideFlag="${nodeHideFlags[$((indexNo-1))]}"

    local modifiedTitlelineContent="${depth_markers} ${title} [${progress},${modifySymbol},${hideFlag}]"

    sed -i "${targetLineNo} c ${modifiedTitlelineContent}" "${inputFile}"

    displayLastTree
    exit 0
  }

  ##############################################################################
  # 選択ノードに不可視フラグを切り替え。指定シンボルを空にした場合は0(可視)
  # 引数:なし(グローバルのみ)
  # 引数2:フラグ(1/0)
  ##############################################################################
  function setHideFlag {

    local targetLineNo="${nodeStartLines[$((${indexNo}-1))]}"

    local presentHideFlag="${nodeHideFlags[$((indexNo-1))]:=0}"
    presentHideFlag="${presentHideFlag:0:1}" #不正な文字が入っていた場合に1文字に削る

    if [[ ${presentHideFlag} -eq 0 ]] ; then
      modifyHideFlag=1
    else
      modifyHideFlag=0
    fi

    local depth_markers="$( seq ${nodeDepths[$((indexNo-1))]} | while read -r line; do printf '#'; done )"
    local title="${nodeTitles[$((indexNo-1))]}"
    local progress="${nodeProgress[$((indexNo-1))]}"
    local symbol="${nodeSymbols[$((indexNo-1))]}"

    local modifiedTitlelineContent="${depth_markers} ${title} [${progress},${symbol},${modifyHideFlag}]"

    sed -i "${targetLineNo} c ${modifiedTitlelineContent}" "${inputFile}"

    displayLastTree
    exit 0
  }

  ##############################################################################
  # 配下ノードに不可視フラグ(1:不可視/0:可視)を設定。指定シンボルを空にした場合は0(可視)
  # 引数:なし(グローバルのみ)
  # 引数2:フラグ(1/0)
  ##############################################################################
  function hideGroup {
    local SelectGroupNodeFromTo="$(getNodeNoInGroup ${indexNo} '' )"
    local startNodeSelectGroup="$( echo ${SelectGroupNodeFromTo} | cut -d ' ' -f 1 )"
    local endNodeSelectGroup="$( echo ${SelectGroupNodeFromTo} | cut -d ' ' -f 2 )"

    local modifiedTitlelineContent=''
    local modifyFlag="${option:0:1}" #先頭1文字のみ

    local depth_markers=''
    local title=''
    local progress=''
    local symbol=''

    for i in $(seq "${startNodeSelectGroup}" "${endNodeSelectGroup}") ;
    do
      tgtLine="$( getLineNo ${i} 1 )"

      depth_markers="$( seq ${nodeDepths[$((i-1))]} | while read -r line; do printf '#'; done )"
      title="${nodeTitles[$((i-1))]}"
      progress="${nodeProgress[$((i-1))]}"
      symbol="${nodeSymbols[$((i-1))]}"

      modifiedTitlelineContent="${depth_markers} ${title} [${progress},${symbol},${modifyFlag}]"
      sed -i "${tgtLine}c ${modifiedTitlelineContent}" "${inputFile}"
    done

    displayLastTree
    exit 0

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

: "タイトル取得系" && {
  ##############################################################################
  # ノードタイトル取得(タイトル部分のみ)
  # 対象ノードのタイトルを取得する
  # 引数1:対象ノード番号
  # 戻り値:なし
  # 標準出力:対象ノードのタイトル
  ##############################################################################
  function getNodeTitle {
    
    local selectNode="${1}"
    echo "${nodeTitles[$((selectNode-1))]}"

  }
  ##############################################################################
  # ノードタイトル取得(タイトル行全体)
  # 対象ノードのタイトル行全体を取得する
  # 引数:なし(グローバルのみ)
  # 戻り値:なし
  # 標準出力:対象ノードのタイトル行全体
  ##############################################################################
  function getNodeTitlelineContent {
    local selectNodeLineNo="${nodeStartLines[ $(( ${1}-1 )) ]}"
    echo "${fileLines[$((selectNodeLineNo-1))]}"
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

: "ノード閲覧コマンド" && {

  ##############################################################################
  # v:対象のノードを閲覧する
  ##############################################################################
  function viewNode {

    selectNodeLineFromTo="$( getLineNo ${indexNo} '' )"
    local selectNodeArray=($selectNodeLineFromTo)
    startLineSelectNode="${selectNodeArray[0]}"
    endLineSelectNode="${selectNodeArray[1]}"

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

    "${selected_viewer}" "${tmpfileSelect}"
    displayLastTree
    exit 0
  }

  ##############################################################################
  # 選択ノードから、下方向に選択ノードよりも深さが深い限り続くノード範囲を対象に、閲覧する
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function groupView {

    local tgtGroup="$( getNodeNoInGroup ${indexNo} '' )"
    local startLineSelectGroup="$( getLineNo $( echo ${tgtGroup} | cut -d ' ' -f 1 ) 1 )"
    local endLineSelectGroup="$( getLineNo $( echo ${tgtGroup} | cut -d ' ' -f 2 ) 9 )"

    cat "${inputFile}" | sed -sn "${startLineSelectGroup},${endLineSelectGroup}p" > "${tmpfileTarget}"
    "${selected_viewer}" "${tmpfileTarget}"
    displayLastTree
    exit 0
  }
}

: "範囲文字数カウント表示" && {
  ##############################################################################
  # 開始行数から数量行数までの、空行とノードタイトル行を除外した文字数をカウントする
  # 引数1:開始行数
  # 引数2:終了行数
  # 戻り値:なし
  # 標準出力:文字数
  ##############################################################################
  function groupCharCount {

    local lineStart="${1}"
    local lineEnd="${2}"
    
    local contentLines=""
    for ((lineNum=lineStart; lineNum<=lineEnd; lineNum++)); do
      local line="${fileLines[$((lineNum-1))]}"
      if [[ ! "${line}" =~ ^#.+ ]] ; then
        contentLines+="${line}"
      fi
    done
    echo "${#contentLines}"

  }
  
  ##############################################################################
  # 選択ノードから、下方向に選択ノードよりも深さが深い限り続くノード範囲を対象に、文字数をカウントして表示する。
  # 空行と、ノードタイトル行は除外する。
  # 引数:なし(グローバルのみ)
  # 標準出力:文字数表示(アナウンス)
  ##############################################################################
  function dispGroupCharCount {

    local tgtGroupStart="$( getLineNo $( getNodeNoInGroup ${indexNo} 1 ) 1 )"
    local tgtGroupEnd="$( getLineNo $( getNodeNoInGroup ${indexNo} 9 ) 9 )"

    count="$( groupCharCount ${tgtGroupStart} ${tgtGroupEnd} )"

    printf "ノード番号%dの配下の文字数合計 : %d\n" "${indexNo}" "${count}"
    printf "※ %d行目から%d行目。空行とノードタイトル行の文字含まず。\n" "${tgtGroupStart}" "${tgtGroupEnd}"
  }
}

: "ツリー表示系" && {
  ##############################################################################
  # コマンド実行後のツリー表示復帰用。直前に発行されたツリーコマンドを発行する
  ##############################################################################
  function displayLastTree {
    case "${previousTreeCommand}" in
      't')  bash "${0}" "${inputFile}" "${previousTreeCommand}" "${previousHideFlag}"
            ;;
      'tl') bash "${0}" "${inputFile}" "${previousTreeCommand}" "${previousHideFlag}"
            ;;
      'ta') bash "${0}" "${inputFile}" "${previousTreeCommand}" "${previousHideFlag}"
            ;;
      'f')  bash "${0}" "${inputFile}" "${previousTreeCommand}" "${previousIndexNo}" "${previousHideFlag}"
            ;;
      'fl') bash "${0}" "${inputFile}" "${previousTreeCommand}" "${previousIndexNo}" "${previousHideFlag}"
            ;;
      'fa') bash "${0}" "${inputFile}" "${previousTreeCommand}" "${previousIndexNo}" "${previousHideFlag}"
            ;;
      *) ;;
    esac
  }

  ##############################################################################
  # ツリー表示する
  # t:通常ツリー
  # tl:開始行番号付きツリー表示
  # ta:開始終了行番号深さ付きツリー表示
  # 先頭から末尾を指定してツリービューを呼び出すラッパー
  ##############################################################################
  function displayTree {

    local indexNoToOption="${indexNo}"
    local indexNo=''
    tree 1 "${maxNodeCnt}" "${indexNoToOption}" "${allCharCount}"
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
    local focusCount="$( groupCharCount $( getLineNo ${startNodeSelectGroup} 1 ) $( getLineNo ${endNodeSelectGroup} 9 ) )"
    
    tree "${startNodeSelectGroup}" "${endNodeSelectGroup}" "${option}" "${focusCount}"

  }

  ##############################################################################
  # ツリー表示する
  # t:通常ツリー
  # tl:開始行番号付きツリー表示
  # ta:開始終了行番号深さ付きツリー表示
  # 引数1: hiddenフラグの有効無効(h:有効/他:無効)
  ##############################################################################
  function tree {
    local startNodeSelectGroup="${1}"
    local endNodeSelectGroup="${2}"
    local hiddenOption="${3}"
    local allCharCount="${4}"

    savePrevTreeCmd "${action}" "${indexNo}" "${hiddenOption}"

    printf "【$(basename ${inputFile})】合計${allCharCount}文字"
    
    case "${char1}" in
      't')  echo '';;
      'f')  echo " ★ フォーカス表示中";;
      *)    echo '';;
    esac
    case "${char2}" in
      '') echo '節   済 アウトライン'
          echo '====+==+============'
          ;;
      'l')  echo '節   行番号   字数   済 アウトライン'
            echo '====+========+======+==+============'
            ;;
      'a')  echo '節   行番号            深  字数   済 視 アウトライン'
            echo '====+========+========+===+======+==+==+============'
            ;;
      *)    ;;
    esac

    seq "${startNodeSelectGroup}" "${endNodeSelectGroup}" | {
      while read -r cnt ; do
        startLine="$( getLineNo ${cnt} 1 )"
        endLine="$(   getLineNo ${cnt} 9 )"
        depth="$( getDepth ${cnt} )"

        count="${nodeCharCount[$((cnt-1))]}"
        progress="${nodeProgress[$((cnt-1))]:=0}"
        hideFlag="${nodeHideFlags[$((cnt-1))]:=0}"

        if [[ "${hideFlag}" = '1' ]] && [[ "${hiddenOption}" = 'h' ]]; then
          continue
        fi

        if [[ ${progress} -eq 1 ]] ; then
          progress='☑️ '
        else
          progress='⬜️'
        fi

        if [[ "${hideFlag}" = '1' ]] ; then
          hideFlag='🕶️ '
        else
          hideFlag='  '
        fi

        symbols="${nodeSymbols[$((cnt-1))]}"

        printf "%4d" "${cnt}"

        case "${char2}" in
          '')  printf " %s" "${progress}"
                ;;
          'l') printf " %8d %6d %s" "${startLine}" "${count}" "${progress}"
                ;;
          'a') printf " %8d~%8d %3d %6d %s %s" "${startLine}" "${endLine}" "${depth}" "${count}" "${progress}" "${hideFlag}"
                ;;
          *)    ;;
        esac

        seq ${depth} | while read -r line; do printf ' '; done
        
        case "${depth}" in
          '1') printf '📚️ '
              ;;
          '2') printf '└📗 '
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

        printf "%s " "${symbols}"

        echo "$( getNodeTitle ${cnt} )"

      done

    }

    echo '❓️引数なしでhelp参照'
    exit 0
   
  }
}

: "ノード出力系コマンド" && {
  ##############################################################################
  # 配下ノードを含んだ範囲を別ファイルに出力する
  # 引数1: 出力ファイルパス(ファイル名含)
  # ノード指定と入力ファイルはグローバルから取得
  ##############################################################################
  function outputGroup {

    local outputFile="${1}"


    if [[ -z "${outputFile/ /}" ]] ; then
      local nodeTitles="${nodeTitles[$((${indexNo}-1))]}"
      outputFile="./${nodeTitles}.txt"
      echo "出力ファイル名の指定がなかったため、ノード名を使用します。"
    fi

    if [[ -f "${outputFile}" ]] ; then
      printf "出力先に既に同名のファイルがあります。上書きしますか？ (y/n)\n>"
      read yn
      if [[ "${yn}" != 'y' ]] ; then
        echo "出力を中止しました。"
        exit 0
      fi
    fi

    local selectGroupFromTo="$( getNodeNoInGroup ${indexNo} '' )"
    local startLineSelectGroup="$( getLineNo $( echo ${selectGroupFromTo} | cut -d ' ' -f 1 ) 1 )"
    local endLineSelectGroup="$( getLineNo $( echo ${selectGroupFromTo} | cut -d ' ' -f 2 ) 9 )"

      cat "${inputFile}" \
    | sed -n "${startLineSelectGroup},${endLineSelectGroup}p" \
    | sed '/^\/\//d' \
    | sed '/^##*/s/\[[^]]*\]//g' \
    | sed 's/^\(##*\)\t/\1 /' \
    > "${outputFile}"
    
    echo "ノード範囲を出力しました: ${outputFile}"
    exit 0
  }
}

: "ノード編集コマンド" && {
  ##############################################################################
  # e:対象のノードを編集する
  ##############################################################################
  function editNode {

    local originalStartLine
    local originalEndLine
    if [[ -n "${option}" ]]; then
        originalStartLine="$( getLineNo ${indexNo} 1 )"
        if [[ "${option}" == "-" ]]; then
            originalEndLine="${maxLineCnt}"
        else
            originalEndLine="$( getLineNo ${option} 9 )"
        fi
    else
        local selectNodeLineFromTo="$( getLineNo ${indexNo} '' )"
        local selectNodeArray=($selectNodeLineFromTo)
        originalStartLine="${selectNodeArray[0]}"
        originalEndLine="${selectNodeArray[1]}"
    fi

    # エディタ用に範囲を前後に拡張する
    if [[ ${originalStartLine} -le 1 ]]; then
        startLineSelectNode=1
    else
        startLineSelectNode=$(( originalStartLine - edit_mode_extend_lines ))
        if [[ ${startLineSelectNode} -lt 1 ]]; then
            startLineSelectNode=1
        fi
    fi

    if [[ ${originalEndLine} -ge ${maxLineCnt} ]]; then
        endLineSelectNode=${maxLineCnt}
    else
        endLineSelectNode=$(( originalEndLine + edit_mode_extend_lines ))
        if [[ ${endLineSelectNode} -gt ${maxLineCnt} ]]; then
            endLineSelectNode=${maxLineCnt}
        fi
    fi

    endLineHeader="$(( ${startLineSelectNode} -1 ))"
    startLineFooter="$(( ${endLineSelectNode} +1 ))"

    (
      if [[ ${startLineSelectNode} -eq 1 ]]; then
        printf '' > "${tmpfileHeader}"
      else
        cat "${inputFile}" | { head -n "${endLineHeader}" > "${tmpfileHeader}"; cat >/dev/null;}
      fi
      wait
    )
    (
      # 以前の複雑な条件分岐を単純化
      cat "${inputFile}" | { sed -n "${startLineSelectNode},${endLineSelectNode}p" > "${tmpfileSelect}"; cat >/dev/null;}
      wait
    )
    (
      if [[ ${endLineSelectNode} -ge ${maxLineCnt} ]] ; then
        printf '' > "${tmpfileFooter}"
      else
        tail -n +"${startLineFooter}" "${inputFile}" > "${tmpfileFooter}"
      fi
      wait
    )

    "${selected_editor}" "${tmpfileSelect}"
    wait
    sed -i -e '$a\' "${tmpfileSelect}" #編集の結果末尾に改行がない場合'
    cat "${tmpfileHeader}" "${tmpfileSelect}" "${tmpfileFooter}" > "${inputFile}"

    displayLastTree
    exit 0
  }
}

: "ノード挿入コマンド" && {
  ##############################################################################
  # 対象のノードの下に新しいノードを挿入する
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function insert {
    if [[ -z "${indexNo}" ]] ; then
      indexNo="${maxNodeCnt}"
    fi

    nlString="${option:-名称未設定}"
    endLinePreviousNode="$( getLineNo ${indexNo} 9 )"
    startLineNextNode="$(   getLineNo $(( ${indexNo} +1 )) 1 )"

    depth="$( getDepth ${indexNo} )"
    dots="$(seq ${depth} | while read -r line; do printf '#'; done)"

    echo -e "${dots} ${nlString} [,,]" > "${tmpfileSelect}"
    cat "${inputFile}" | { head -n "${endLinePreviousNode}" > "${tmpfileHeader}"; cat >/dev/null;}

    if [[ ${indexNo} -eq ${maxNodeCnt} ]] ;then
      awk 1 "${inputFile}" "${tmpfileSelect}" > "${tmpfile1}"
      cat "${tmpfile1}" > "${inputFile}"

    else
      cat "${inputFile}" | { tail -n +${startLineNextNode}  > "${tmpfileFooter}"; cat >/dev/null;}
      cat "${tmpfileHeader}" "${tmpfileSelect}" "${tmpfileFooter}" > "${inputFile}"
    fi
  }

  ##############################################################################
  # 対象のノードの下に新しいノードを挿入する
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function insertEdit {
    insert
    bash "${0}" "${inputFile}" 'e' "$((${indexNo} + 1))"
    exit 0
  }

  ##############################################################################
  # 対象のノードの下に新しいノードを挿入する
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function insertNode {    
    insert
    displayLastTree
    exit 0
  }
}

: "単ノード深さ変更コマンド" && {
  ##############################################################################
  # 対象のノード一つだけの深さを変更する
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function slideNode {

    tgtLine="$(getLineNo ${indexNo} 1 )"

    case "${char2}" in
      'l')  sed -i -e "${tgtLine} s/^##/#/g" "${inputFile}"
            ;;
      'r')  sed -i -e "${tgtLine} s/^/#/g" "${inputFile}"
            ;;
      *)    echo 'err'
            exit 9
            ;;
    esac

    displayLastTree
    exit 0

  }
}

: "単ノード上下交換コマンド" && {
  ##############################################################################
  # 対象のノード一つだけを上下に移動する(指定の方向のノードと入れ替える)
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function swapNode {

    local indexTargetNode=''
    local indexNextNode=''
    local endLinePreviousNode=''
    local startLineTargetNode=''
    local endLineTargetNode=''
    local targetNodeLineFromTo=''

    local indexSelectNode="$(( ${indexNo} ))"
    local selectNodeLineFromTo="$( getLineNo ${indexSelectNode} '' )"
    local selectNodeArray=($selectNodeLineFromTo)
    local startLineSelectNode="${selectNodeArray[0]}"
    local endLineSelectNode="${selectNodeArray[1]}"

    case "${char2}" in
      'u')  indexTargetNode="$(( ${indexNo} -1 ))"
            #indexSelectNode="$(( ${indexNo}    ))"
            indexNextNode="$((   ${indexNo} +1 ))"

            endLinePreviousNode="$(( $( getLineNo ${indexTargetNode} 1 ) - 1 ))"

            targetNodeLineFromTo="$( getLineNo ${indexTargetNode} '' )"
            local targetNodeArray=($targetNodeLineFromTo)
            startLineTargetNode="${targetNodeArray[0]}"
            endLineTargetNode="${targetNodeArray[1]}"

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
            local targetNodeArray=($targetNodeLineFromTo)
            startLineTargetNode="${targetNodeArray[0]}"

            if [[ ${indexNo} -eq ${maxNodeCnt} ]] ; then
              endLineTargetNode="${#fileLines[@]}"
            else
              endLineTargetNode="${targetNodeArray[1]}"
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

    displayLastTree
    exit 0
  }
}

: "配下ノード深さ変更コマンド" && {
  ##############################################################################
  # 対象のノードとその配下の深さを、一緒に変更する
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function slideGroup {

    local SelectGroupNodeFromTo="$( getNodeNoInGroup ${indexNo} '' )"
    local selectGroupArray=(${SelectGroupNodeFromTo})
    local startNodeSelectGroup="${selectGroupArray[0]}"
    local endNodeSelectGroup="${selectGroupArray[1]}"

    case "${char3}" in
      'l')  for i in $(seq "${startNodeSelectGroup}" "${endNodeSelectGroup}") ;
            do
              tgtLine="$( getLineNo ${i} 1 )"
              sed -i -e "${tgtLine} s/^##/#/g" "${inputFile}"
            done
            ;;
      'r')  for i in $(seq "${startNodeSelectGroup}" "${endNodeSelectGroup}") ;
            do
              tgtLine="$( getLineNo ${i} 1 )"
              sed -i -e "${tgtLine} s/^#/##/g" "${inputFile}"
            done
            ;;
      *)    echo 'err'
            read -s -n 1 c
            exit 9
            ;;
    esac

    displayLastTree
    exit 0

  }
}

: "配下ノード上下交換コマンド" && {
  ##############################################################################
  # 対象のノードとその配下と、対象ノードと同じ高さの上下ノードとその配下とを、同時に入れ替える
  # 引数:なし(グローバルのみ)
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
      local selectNodeArray=($selectNodeLineFromTo)
      startLineSelectGroup="$(getLineNo ${selectNodeArray[0]} 1 )"
      endLineSelectGroup="$(  getLineNo ${selectNodeArray[1]} 9 )"

    }

    : "移動先グループ情報を取得" && {
      #上移動の場合
      ##かつ対象ノードが一番上の場合
      targetNodeLineFromTo="$(getTargetNodeNoInGroup "${indexNo}" "${direction}" '' )" 
      if [[ "${?}" -ne 0 ]] ; then
        echo '交換移動可能なグループがありません'
        read -s -n 1 c
        displayLastTree
        exit 0
      else
        local targetNodeArray=($targetNodeLineFromTo)
        startLineTargetGroup="$(getLineNo ${targetNodeArray[0]} 1 )"
        endLineTargetGroup="$(  getLineNo ${targetNodeArray[1]} 9 )"
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
    displayLastTree
    exit 0

  }
}

: "ノード削除コマンド" && {
  ##############################################################################
  # d:対象のノードを削除する
  ##############################################################################
  function deleteNode {

    selectNodeLineFromTo="$( getLineNo ${indexNo} '' )"
    local selectNodeArray=($selectNodeLineFromTo)
    startLineSelectNode="${selectNodeArray[0]}"
    endLineSelectNode="${selectNodeArray[1]}"

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

    cat "${tmpfileHeader}" "${tmpfileFooter}" > "${inputFile}"

    displayLastTree
    exit 0
  }

  ##############################################################################
  # 対象のノードとその配下を削除する
  # 引数:なし(グローバルのみ)
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

    displayLastTree
    exit 0
  }
}

: "ノード結合" && {
  ##############################################################################
  # ノード結合
  # 引数:なし(グローバルのみ)
  # 指定のノードに、指定のノードのひとつ下のノードを結合する。
  ##############################################################################
  function joinNode {

    local tgtLine="$( echo ${nodeStartLines[${indexNo}]} )"
    sed -i "${tgtLine}d" "${inputFile}"
    displayLastTree
    exit 0
  }

  ##############################################################################
  # 配下ノード結合
  # 引数:なし(グローバルのみ)
  # 指定のノードに、指定のノード配下のノードすべてを結合する
  ##############################################################################
  function joinGroup {

    local selectGroupNodeFromTo="$( getNodeNoInGroup ${indexNo} '' )"
    local startNodeSelectGroup="$( echo ${selectGroupNodeFromTo} | cut -d ' ' -f 1 )"
    local endNodeSelectGroup="$(   echo ${selectGroupNodeFromTo} | cut -d ' ' -f 2 )"

    local startLineSelectGroup="$( getLineNo ${startNodeSelectGroup} 1 )"
    local endLineSelectGroup="$(   getLineNo ${endNodeSelectGroup} 9 )"

    local endLineHeader="$(( ${startLineSelectGroup} - 1 ))"
    local startLineFooter="$(( ${endLineSelectGroup} + 1 ))"

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
        cat "${inputFile}" | { sed -n "1, ${endLineSelectGroup}p" > "${tmpfileSelect}"; cat >/dev/null;}
      else
        if [[ ${indexNo} -eq ${maxNodeCnt} ]] ; then
          cat "${inputFile}" | { tail -n +${startLineSelectGroup}  > "${tmpfileSelect}"; cat >/dev/null;}
        else
          cat "${inputFile}" | { sed -n "${startLineSelectGroup},${endLineSelectGroup}p" > "${tmpfileSelect}"; cat >/dev/null;}
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

    local titleLine="$(cat ${tmpfileSelect} | head -n 1)"
    local content="$(tail -n +2 ${tmpfileSelect} | sed -E 's/^#+\s.+\[.+\]//g')"

    echo -e "${titleLine}\n${content}" > "${tmpfileSelect}"
    sed -i -e '$a\' "${tmpfileSelect}" #編集の結果末尾に改行がない場合'
    
    cat "${tmpfileHeader}" "${tmpfileSelect}" "${tmpfileFooter}" > "${inputFile}"

    displayLastTree
    exit 0
  }
}

: "バックアップ関数" && {
  ##############################################################################
  # バックアップ作成
  # 引数:なし(グローバルのみ)
  ##############################################################################
  function makeBackup {
    local orgFile="${inputFile}"
    local MAX_BACKUP_COUNT=3
  
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

: "前回使用tree系コマンド保持関数" && {
  ##############################################################################
  # 前回使用tree系コマンド保持関数
  # 引数1:保持するコマンド(t,tl,ta,f,fl,fa)のみ想定
  # 引数2:保持するノード番号
  # 引数3:保持する不可視オプション
  # 想定外のコマンドを渡された場合、エラーとせず読み捨てる
  ##############################################################################
  function savePrevTreeCmd {
    local lastTreeCommand="${1}"
    local lastIndexNo="${2}"
    local lastHideFlag="${3}"

    local SCRIPT_DIR="$(cd $(dirname ${0}); pwd)"
	  local SCRIPT_PATH="${SCRIPT_DIR}/${0}"

    local replaceFrom=''
	  local replaceToTmp=''
	  local replaceTo=''

    ##ツリー系コマンドの保持
    replaceFrom=$(grep -E "^ *readonly previousTreeCommand=" "${SCRIPT_PATH}")
	  replaceToTmp=$(echo "${replaceFrom}" | grep -oE "'[^']{1,2}'")
	  replaceTo="${replaceFrom/${replaceToTmp}/\'${lastTreeCommand}\'}"

    sed -i "s/${replaceFrom}/${replaceTo}/" "${SCRIPT_PATH}"

    ##ノード番号の保持
    if [[ "${lastTreeCommand}" =~ (f|fl|fa) ]] ; then
      replaceFrom=$(grep -E "^ *readonly previousIndexNo=" "${SCRIPT_PATH}")
      replaceToTmp=$(echo "${replaceFrom}" | grep -oE "'[0-9]*'")
      replaceTo="${replaceFrom/${replaceToTmp}/\'${lastIndexNo}\'}"
    else
      replaceFrom=$(grep -E "^ *readonly previousIndexNo=" "${SCRIPT_PATH}")
      replaceToTmp=$(echo "${replaceFrom}" | grep -oE "'[0-9]*'")
      replaceTo="${replaceFrom/${replaceToTmp}/\'${lastIndexNo}\'}"
    fi

    sed -i "s/${replaceFrom}/${replaceTo}/" "${SCRIPT_PATH}"

    ##不可視オプションの保持
    replaceFrom=$(grep -E "^ *readonly previousHideFlag=" "${SCRIPT_PATH}")
    replaceToTmp=$(echo "${replaceFrom}" | grep -oE "'.*'")
    replaceTo="${replaceFrom/${replaceToTmp}/\'${lastHideFlag}\'}"

    sed -i "s/${replaceFrom}/${replaceTo}/" "${SCRIPT_PATH}"

  }
}

: "初期処理" && {
  ##############################################################################
  # 初期処理
  ##############################################################################
  function myInit {

    # ファイル内の改行コードをcrlfからlfに修正する
    convert_crlf_to_lf

    # ノード行の自動補正
    sanitizeNodeLines

    #横幅取得
    maxRowLength="$( tput cols )"

    #ノード情報検出
    detectNode
    
    #指定ファイルがノード情報を持っていなかった場合、追加する。
    if [[ ${maxNodeCnt} -eq 0 ]] ; then
      echo 'ノードがありません。先頭に第一ノードを追加します' 
      if [ ! -s "${inputFile}" ] ; then
        echo -e "# 1st Node [,,]\n" > "${inputFile}"
      else
        sed -i "1i# 1st Node [,,]" "${inputFile}"
      fi
      read -s -n 1 c
      displayLastTree
      exit 0
    fi

    #全体文字数(ノードタイトル行と空行を除く)のカウント
    local allContentLines=""
    for line in "${fileLines[@]}"; do
      if [[ ! "${line}" =~ (^#.+|^//.+) ]]; then
        allContentLines+="${line}"
      fi
    done
    allCharCount="${#allContentLines}"


    #エディタの設定
    #editorList配列の優先順で存在するコマンドに決定される。
    #ユーザによる書き換えも想定
    #(selected_editor部分を任意のエディター起動コマンドに変更)
    editorList=("${selected_editor}" 'edit' 'micro' 'nano' 'vi' 'ed')
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
    viewerList=("${selected_viewer}" 'less' 'more' 'view' 'cat')
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
      displayLastTree
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
      displayLastTree
      exit 0
    fi

    if [[ ${action} = 'ta' ]] && [[ ${maxRowLength} -le 50 ]] ; then
      if [[ ${maxRowLength} -le 40 ]] ; then
        echo "画面の横幅が足りないため表示を縮退します"
        read -s -n 1 c
        bash "${0}" "${inputFile}" 't'
        exit 0
      else
        echo "画面の横幅が足りないため表示を縮退します"
        read -s -n 1 c
        bash "${0}" "${inputFile}" 'tl'
        exit 0
      fi
    fi
    if [[ ${action} = 'tl' ]] && [[ ${maxRowLength} -le 40 ]] ; then
      echo "画面の横幅が足りないため表示を縮退します"
      read -s -n 1 c
      bash "${0}" "${inputFile}" 't'
      exit 0
    fi

    ######################################
    #バックアップ作成
    ######################################
    makeBackupActionList=('e' 'd' 'i' 'ie' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd' 'c' 's')
    if arrayContains "${action}" "${makeBackupActionList[@]}"; then
      makeBackup
    fi

  }
}

: "パラメーターチェック" && {
  ##############################################################################
  # 引数:なし(グローバルのみ)
  # 戻り値:0(成功)/9(失敗)
  ##############################################################################
  function parameterCheck {
    
    #動作指定のチェック
    allowActionList=('h' 'gh' 'e' 'd' 'gd' 'i' 'ie' 't' 'th' 'tl' 'ta' 'f' 'fl' 'fa' 'v' 'gv' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd' 'j' 'gj' 'k' 'gk' 'gc' 's' 'o')
    if ! arrayContains "${action}" "${allowActionList[@]}"; then
      echo '引数2:無効なアクションです'
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=('h' 'gh' 'e' 'd' 'gd' 'f' 'fl' 'fa' 'v' 'gv' 'ml' 'mr' 'md' 'mu' 'gml' 'gmr' 'gmu' 'gmd' 'j' 'gj' 'k' 'gk' 'gc' 's' 'o')
    if arrayContains "${action}" "${allowActionList[@]}"; then
      if [[ ${indexNo} = '' ]] ; then
        echo "ノードを指定してください"
        read -s -n 1 c
        return 1
      fi
    fi
    if arrayContains "${action}" "${allowActionList[@]}"; then
      if [[ ! "${indexNo}" =~ ^[0-9]+$ ]] ; then
        echo "ノード番号の指定が不正です：${indexNo}"
        read -s -n 1 c
        return 1
      fi
    fi
    if arrayContains "${action}" "${allowActionList[@]}"; then
      if [[ ${indexNo} -le 0 ]] || [[ ${indexNo} -gt ${maxNodeCnt} ]] ; then
        echo "${indexNo}番目のノードは存在しません"
        read -s -n 1 c
        return 1
      fi
    fi

    local depth=$(getDepth ${indexNo})

    #動作指定とノード番号のチェック(ノード状態の取得が必要なチェックは後続で実施)
    unset allowActionList
    allowActionList=('ml' 'gml')
    if arrayContains "${action}" "${allowActionList[@]}" && [[ ${depth} -le 1 ]] ; then
      echo "ノード番号${indexNo}はこれ以上浅く(左に移動)できません"
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=('mr' 'gmr')
    if arrayContains "${action}" "${allowActionList[@]}" && [[ ${depth} -ge 10 ]] ; then
      echo "ノード番号${indexNo}の深さは${depth}です。これ以上深く(右に移動)できません"
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=('mu' 'gmu')
    if arrayContains "${action}" "${allowActionList[@]}" && [[ ${indexNo} -eq 1 ]] ; then
      echo '引数2:1番目のノードは上に移動できません'
      read -s -n 1 c
      return 1
    fi

    unset allowActionList
    allowActionList=('md' 'gmd')
    if arrayContains "${action}" "${allowActionList[@]}" && [[ ${indexNo} -ge ${maxNodeCnt} ]] ; then
      echo "引数2:${indexNo}番目のノードは下に移動できません"
      read -s -n 1 c
      return 1
    fi

  }
}

: "一時ファイルにかかる処理" && {
  ##############################################################################
  # 一時ファイル削除
  # 引数:なし(グローバルのみ)
  # 戻り値:なし
  ##############################################################################
  function rm_tmpfile {
    [[ -f "${tmpfileHeader}" ]] && rm -f "${tmpfileHeader}"
    [[ -f "${tmpfileSelect}" ]] && rm -f "${tmpfileSelect}"
    [[ -f "${tmpfileTarget}" ]] && rm -f "${tmpfileTarget}"
    [[ -f "${tmpfileFooter}" ]] && rm -f "${tmpfileFooter}"
  }

  ##############################################################################
  # 一時ファイル作成
  # 引数:なし(グローバルのみ)
  # 戻り値:なし
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

: "ファイル内容補正" && {
  ##############################################################################
  # ファイル内の改行コードをcrlfからlfに修正する
  # ※このスクリプトは改行コードとしてlfを想定している。
  # 引数:なし(グローバル変数`inputFile`を参照)
  ##############################################################################
  function convert_crlf_to_lf {
    # dos2unixコマンドが使える場合
    if command -v dos2unix &> /dev/null; then
        dos2unix "${inputFile}" >/dev/null 2>&1
    # sedで代用
    else
        sed -i 's/\r$//' "${inputFile}"
    fi
  }

  ##############################################################################
  # ノード行の自動補正
  # '#'で始まる行がノードメタ情報('[*,*,*]')を持たない場合に、
  # デフォルト値を追記してファイルを上書きする。
  # 引数:なし(グローバル変数`inputFile`を参照)
  ##############################################################################
  function sanitizeNodeLines {
    local tmp_sanitized_file
    tmp_sanitized_file=$(mktemp)

    local file_modified=false
    # ファイルを一行ずつ読み込み、正規化が必要かチェック
    while IFS= read -r line || [ -n "$line" ]; do
      # 行が '#' で始まり、'[*,*,*]' のような属性で終わらない場合
      if [[ "$line" == '#'* ]] && [[ ! "$line" =~ \[.*,.*,.*\]$ ]]; then
        echo "${line} [,,]"
        file_modified=true
      else
        echo "$line"
      fi
    done < "${inputFile}" > "$tmp_sanitized_file"

    if [ "$file_modified" = true ]; then
      mv "$tmp_sanitized_file" "${inputFile}"
    else
      rm "$tmp_sanitized_file"
    fi
  }
}

: "主処理" && {
  ##############################################################################
  # 主処理
  # 引数1:対象ファイルパス
  # 引数2:動作区分
  # 引数3:対象ノード番号
  # 引数4:動作区分に対するオプション指定
  # 戻り値:なし
  ##############################################################################
  function main {
    
    inputFile="${1}"
    action="${2}"
    indexNo="${3}"
    option="${4}"

    if [[ "${action}" == "i" ]] || [[ "${action}" == "ie" ]]; then
      if ! [[ "${indexNo}" =~ ^[0-9]+$ ]] && [[ -n "${indexNo}" ]]; then
        option="${indexNo}"
        indexNo=""
      fi
    fi

    readonly previousTreeCommand='tl'
    readonly previousIndexNo=''
    readonly previousHideFlag=''

    #対象ファイルの存在チェック
    if [[ ! -f ${inputFile} ]] ; then
      echo "${inputFile} というファイルは存在しません。"
      read -p "${inputFile} を作成しますか？(y/n) :" YN
      if [ "${YN}" = "y" ]; then
        touch "${inputFile}"
        displayLastTree
        exit 0
      else
        echo "終了します"
        exit 1;
      fi
    fi

    # 初期処理
    myInit

    #パラメータチェック
    parameterCheck
    if [[ ${?} -ne 0 ]] ; then 
      exit 1
    fi


    makeTmpfile # 一時ファイルを作成

    char1="${action:0:1}"
    char2="${action:1:1}"
    char3="${action:2:1}"

    case "${char1}" in
      'v')  clear
            viewNode
            ;;
      'e')  editNode
            ;;
      'd')  deleteNode
            ;;
      'o')  outputGroup "${option}"
            ;;
      's')  clear
            setSymbol
            ;;
      'j')  clear
            joinNode
            ;;
      'k')  clear
            switchProgress
            ;;
      'h')  clear
            setHideFlag
            ;;
      't')  clear
            displayTree
            ;;
      'm')  case "${char2}" in 
              [ud]) clear
                    swapNode
                    ;;
              [lr]) clear
                    slideNode
                    ;;
              *)  echo 'err'
                  ;;
            esac
            ;;
      'g')  case "${char2}" in 
              'v')  clear
                    groupView
                    ;;
              'c')  dispGroupCharCount
                    ;;
              'k')  setProgressGroup
                    ;;
              'd')  deleteGroup
                    ;;
              'j')  joinGroup
                    ;;
              'h')  hideGroup
                    ;;
              *)  case "${char3}" in 
                    [ud]) clear
                          swapGroup
                          ;;
                    [lr]) clear
                          slideGroup
                          ;;
                    [lr]) clear
                          slideGroup
                          ;;
                    *)  echo 'err'
                        ;;
                  esac
            esac
            ;;
      'f')  clear
            focusMode
            ;;
      'i')  clear
            case "${char2}" in
              '') insertNode
                  ;;
              'e') insertEdit
                  ;;              
            esac
            ;;
      *) ;;
    esac
  }  
}

###########################################
# エントリーポイント
###########################################

if [[ "${1}${2}${3}${4}" = '' ]] ; then
  echo "引数が与えられなかったためヘルプ表示します"
  read -s -n 1 c
  displayHelp
  read -s -n 1 c
  exit 0
fi
if [[ "${1}" = 'h' ]] || [[ "${1}" = '-h' ]] || [[ "${1}" = '--help' ]] || [[ "${1}" = '/h' ]]; then
  displayHelp "${2}"
  read -s -n 1 c
  exit 0
fi

main "${1}" "${2}" "${3}" "${4}"

# 正常終了したときに一時ファイルを削除する
trap rm_tmpfile EXIT
# 異常終了したときに一時ファイルを削除する
trap 'trap - EXIT; rm_tmpfile; exit -1' INT PIPE TERM
