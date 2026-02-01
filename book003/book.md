# はじめに

Symbol ノードの構築例を見ると、多くの場合、bootstrap や shoestring を使用した方法が紹介されています。
これらはいずれも、Docker を前提とした構成です。
（なお、bootstrap は公式では使用が推奨されていません）

私自身も、最初は Docker を使う前提で考えていました。
ただ、いくつかの理由から、

「Docker を使わずにやると、実際どうなるのだろう？」

という素朴な疑問を持つようになりました。

本書は、その疑問から始まり、
実際に Docker を使わずに Symbol ノードを運用してきた中で、

何が起きたか

どこで詰まったか

どこは意外と問題にならなかったか

を整理したものです。

Docker を否定するつもりはありません。
便利な場面も多くあります。

ただ、Docker を使わなかった場合の運用例は、
これまであまりまとまっていませんでした。

そのため、本書では一度きちんと書き残すことにしました。

## 本書の対象読者

本書は、次のような読者を想定しています。

- Symbol ノードを自分で動かしてみたい
- Docker を使わない構成に興味がある
- Linux 環境での基本的な操作ができる
- ノードを「検証」ではなく「運用」してみたい

強い前提知識は必要ありませんが、
コマンドを写して終わるだけの本でもありません。

## 本書は「なぞるための手順書」ではない

本書では、ビルド手順や設定例を具体的に示します。
その意味では、結果的に「手順書」として読める部分も多くあります。

ただし、本書の目的は、
それらの手順をそのまま再現することではありません。

環境や用途によって、

- 選ぶ構成
- 調整の仕方
- 割り切るポイント

は変わります。

本書では、

「この構成で、こういう運用をしたら、こうなった」

という実例を軸に話を進めます。

必要な部分だけを拾い、自分の環境に合わせて調整するための材料として使ってもらえれば十分です。

## 配布バイナリを前提としない理由

Symbol のサーバー（catapult）は、配布済みの実行バイナリを前提とした構成ではありません。<br>
そのため、本書では最初からソースコードを取得してビルドする前提で進めます。

結果的に、

- ビルド環境を意識する
- ライブラリの依存関係を把握する
- 何か起きたときに切り分けしやすくなる

という点では、悪くありませんでした。

次章では、本書で扱うノード構成を整理した上で、
その後の具体的な作業に進みます。

本書の検証および運用環境は、Ubuntu 24.04 LTS を前提としています。

# 第1章 Dockerを使わずにやってみる

## 1.1 Docker 前提の世界

Symbol ノードの構築例としては、Docker を前提とした構成が多く紹介されています。

この点については、すでに「はじめに」で触れた通りです。

本章では、その前提を踏まえた上で、Docker を使わない構成でノードを動かした場合に何が変わったかを整理します。

## 1.2 Docker を使わない構成で変わる点

Docker を使わない構成では、ノードは OS 上のプロセスとして直接起動します。

そのため、次のような点を自分で扱うことになります。

- ビルド環境
- ライブラリの依存関係
- 実行ユーザー
- 起動方法

Docker を使っている場合、これらの多くはコンテナの内側に隠れています。

一方で Docker を使わない構成では、プロセスの状態やファイルの配置はそのまま OS 上で確認できるようになります。

## 1.3 実際に起きたこと

Docker を使わずにノードを動かしてみると、いくつか分かりやすい変化がありました。

まず、初回の準備には時間がかかります。

- 依存関係のビルドに時間がかかる
- ビルドが通らない原因を自分で切り分ける必要がある
- 起動しない場合、ログを直接追う必要がある

一方で、一度動き始めてからは、想像していたほど手間は増えませんでした。

- 設定を変えない限り、挙動は安定する
- 再起動しても、同じ手順で戻せる
- 何か起きたときに、確認すべき場所が明確になる

この辺りは、bootstrapとshoestringと変わりはありません。

## 1.4 続けられた理由

Docker を使わない構成は、準備段階では負担が増えます。

ただし、運用に入ってからは、判断に必要な情報が手元に残ります。

- どの設定が動作に影響するのか
- どこを見れば状態が分かるのか
- どこまでが自分の管理範囲なのか

これらが明確になることで、構成や運用について自分で判断できるようになります。

次章では、こうした前提のもとで、本書で扱うノード構成を整理します。

# 第2章 まずノード構成を決める

Docker を使うかどうかに関わらず、Symbol ノードを運用する際に最初に決めるべきことはノードの構成です。

ビルド手順や設定は、構成によって微妙に変わります。構成を決めないまま進めると、あとから手戻りが発生しやすくなります。そのため本書では、具体的な作業に入る前に、どのような構成があり、何が違うのかを整理します。

## 2.1 本書で扱う前提

本書では、以下を前提とします。

- Peer ノードとしてネットワークに参加する
- Docker は使用しない
- catapult は ソースからビルドする
- API や Voting は、必要に応じて追加する要素として扱う

Symbol ノードには、Peer を持たず API のみを提供する構成も存在します。

ただし、API のみの構成ではハーベストは行えず、
ネットワークへの貢献という意味でも役割は限定的です。
実運用でこの構成を選択するケースは多くありません。

そのため本書では、Peer を持つ構成のみを扱います。

## 2.2 Peer + light API

本書での基準構成は、Peer + light API です。

この構成では、

- Peer としてネットワークに参加する
- MongoDB を持たない
- Rest API は light API のみ提供する

という形になります。

MongoDB を持たないため、API として提供できる機能は限定されますが、

- ノードの負荷が小さい
- ディスク使用量が（ほんの少し）抑えられる
- 運用が比較的シンプル

という特徴があります。

個人でノードを運用する場合、まず現実的なのはこの構成でした。本書の起動例や設定例の多くは、この構成を前提にしています。

## 2.3 Peer + API

Peer + API 構成では、MongoDB を持ち、フル機能の Rest API を提供します。
この構成を Dual ノードとも呼びます。

この構成では、

- 外部サービスからの利用を想定できる
- チェーンデータを柔軟に参照できる

一方で、

- MongoDB の運用が必要になる
- ディスク容量の消費が増える
- ノード全体の負荷が上がる

といった点も無視できません。

「API を公開する」「他者が使う」ことを前提にする場合は、この構成が選択肢になります。

> ### 補足：Peer と MongoDB の同期ズレについて
>
> Peer + API 構成では、
> Peer が保持するチェーン状態と、
> MongoDB に保存されているデータの間に
> 差分が生じることがあります。
>
> この同期ズレは、Peer と MongoDB 間の内部処理が一時的に停止した場合などに発生します。
>
> 同期ズレが発生した場合、
> MongoDB の再同期が必要になり、
> その間、Rest API は利用できなくなります。
>
> <!-- 軽微なズレは復旧可能 -->
>
> 再同期そのものは復旧手段として用意されていますが、
> API 停止時間が発生するという点で、
> 運用コストは確実に増加します。
>
> ハーベストやネットワーク参加を主目的とする場合、
> Peer + light API 構成の方が扱いやすいケースもあります。

## 2.4 Voting を付ける / 付けない

Voting ノードは、API 構成とは独立した要素です。

- Peer + light API + Voting
- Peer + API + Voting

いずれも構成としては成立します。

Voting ノードは、
ブロックチェーンのファイナライズに関与します。

Voting を付けることで、
ネットワークの可用性や継続性に貢献できますが、
その分、ノードを止めにくくなります。

技術的に難しいというより、
運用上の判断が必要になる要素です。

> ### 補足：Voting ノードが関与する「ファイナライズ」
>
> ファイナライズとは、
> 「このブロック以降は確定したものとして扱う」
> という合意を、ネットワーク全体で形成する仕組みです。
>
> Voting ノードは、
> どのブロックを確定させるかについて投票を行います。
>
> そのため、Voting ノードの停止や異常は、
> ネットワーク全体の確定性に影響を与える可能性があります。
>
> ### 注意：Voting ノードの運用条件とリスク
>
> Voting ノードとして運用するためには、
> 一定量以上（300万 XYM 以上）の保有が必要です。
>
> また、Voting キーはファイナライズに直接関与するため、
> 運用を開始したあとに
> 「やめたい」と思っても簡単には停止できません。
>
> 特に、Voting キーを紛失した場合、原則として復旧はできません。
>
> Voting キーはファイナライズに直接関与するため、キーを失った Voting ノードは意図せずファイナライズに影響を与え続ける可能性があります。
>
> Voting を付与するかどうかは、
> 技術的な問題というより、
> 運用責任の問題として判断する必要があります。

## 2.5 構成は積み上げで考える

本書で扱う構成は、次のように積み上げで整理できます。

- Peer
- Peer + light API
- Peer + API
- それぞれに Voting を追加

最初から最大構成を選ぶ必要はありません。

実際には、

- まず light API で動かす
- 必要になったら API を追加する
- 判断できるようになったら Voting を検討する

という形でも問題ありません。

構成ごとの違いを整理すると、次のようになります。

**ノード構成の比較（目安）**

| 構成                | 難易度 | 負荷 | ネットワーク貢献 | 備考                     |
| ------------------- | ------ | ---- | ---------------- | ------------------------ |
| Peer + light API    | 低     | 低   | 中               | 個人運用・ハーベスト向け |
| Peer + API          | 中     | 高   | 高               | 外部向け API 提供        |
| Peer + API + Voting | 高     | 高+  | 非常に高         | 300万 XYM 以上必要       |

構成は、あとから変更できます。その前提で設計しておくことが、長く運用する上では重要でした。

# 第3章 Dockerなし構成の全体像

## 3.1 OS / プロセス構成

本書で扱う構成では、
Symbol ノードは Linux 上のプロセスとして直接起動します。

Docker を使わない場合、
ノードはコンテナの内側ではなく、
OS が管理する通常のプロセスとして動作します。

そのため、

- プロセスの起動・停止
- 権限
- メモリ使用量
- ファイルアクセス

といった要素は、
OS の仕組みそのままで扱うことになります。

特別なことはしていませんが、
「どこで何が動いているか」は把握しやすくなります。

## 3.2 ディレクトリ設計

Docker を使わない構成では、
ファイルの置き場所を自分で決める必要があります。

本書では、
次のような役割分担を前提にしています。

- ビルド成果物
- 設定ファイル
- 実行時に生成されるデータ
- ログ

これらを混ぜないことが、
後から状況を把握しやすくする上で重要でした。

特に、
ビルドしたバイナリと設定ファイルは、
意識的に分けて配置しています。

## 3.3 起動・停止の考え方

Docker を使わない場合、
ノードの起動方法は複数考えられます。

- 直接コマンドを実行する
- スクリプトを用意する
- systemd でサービス化する

本書では、
まず「手動で起動できる」状態を作ることを優先します。

理由は単純で、
何か起きたときに、
一つずつ確認しやすいからです。

サービス化については、
後の章で改めて扱います。

## 3.4 シンプルさを優先した理由

Docker を使わない構成を選んだことで、
便利さをいくつか手放しています。

その代わりに、

- 状態を追いやすい
- 問題の切り分けがしやすい
- どこまでが自分の管理範囲か分かる

という利点がありました。

すべてを抽象化するのではなく、
追える範囲で運用する。

本書の構成は、
そのための一つの例に過ぎません。

# 第4章 ビルドは避けて通れない

## 4.1 なぜバイナリ配布ではなくビルドなのか

Symbol ノードを運用するにあたって、
ビルド作業は避けて通れません。

一般的なサーバーアプリケーションでは、
特定の OS 向けにビルド済みのバイナリが配布され、
それを配置して起動するだけで利用できることも少なくありません。

Symbol ノードには、
そのような ホスト OS 向けの公式バイナリ配布は存在しません。

一方で、Docker 環境では、
ビルドおよび環境構築が完了した
コンテナイメージという形で配布されています。

このコンテナイメージは、

- ビルド済みであること
- 依存ライブラリが揃っていること
- 起動に必要な前提が整っていること

という点において、
実質的にはバイナリ配布と同等のものです。

ただし、それは
特定の前提条件（OS・ライブラリ・実行環境）を
コンテナ内部に固定したうえで成立している
という点が異なります。

本書では、
この前提条件をあらかじめ固定せず、
ホスト環境に直接ノードを構築する方法を扱います。

その結果として、
ビルド作業は必須となります。

これは制約というより、
「どの環境で、何が動いているのか」を
運用者自身が把握したうえでノードを運用する、
という立場を選択した結果です。

以降の節では、
このビルド作業を特別なものとして扱うのではなく、
通過点として淡々と越えるための前提条件を整理していきます。

## 4.2 ビルドに必要な前提環境

Symbol ノードのビルドは、
特別な最適化や調整を必要とする作業ではありません。
一方で、事前に満たしておくべき前提条件はいくつか存在します。

これらを満たしていない場合、
ビルドの途中でエラーが発生したり、
ビルド自体は成功しても、起動時に問題が表面化することがあります。

本節では、
「とりあえず先へ進むために必要な最低限の前提」
に絞って整理します。

### 4.2.1 対象とする実行環境

本書では、
Linux 環境でのビルドを前提とします。

具体的には、
Ubuntu の LTS 系ディストリビューションを想定しています。
他の Linux 環境でもビルド可能ですが、
パッケージ名や依存関係が異なるため、
以降の手順はそのままでは適用できません。

Windows や macOS についても、
ビルド自体は可能ですが、
本書では対象外とします。

これは難易度の問題ではなく、
実運用環境として Linux が前提になりやすいためです。

### 4.2.2 必要なツールとライブラリ

ビルドに必要となるツールは、
一般的な C++ プロジェクトと大きくは変わりません。

最低限、以下のものが必要です。

- C++ コンパイラ一式
- cmake
- git
- ビルドに必要な各種ライブラリ

詳細なパッケージ名やインストールコマンドについては、
後述の手順でまとめて示します。

ここで重要なのは、
特別な独自ツールは不要という点です。

### 4.2.3 ファイルディスクリプタ制限について

Symbol ノードは、
内部で多数のファイルディスクリプタを使用します。

これは、
P2P 通信、データベースアクセス、
各種内部処理を並行して行う設計によるものです。

そのため、
OS のデフォルト設定のままでは、
起動時や負荷がかかったタイミングで
問題が発生することがあります。

特に多いのが、

- ビルド後に起動するとすぐ落ちる
- 接続数が増えた途端に不安定になる
- 明確なエラーメッセージが出ない

といった症状です。

本書では、
ビルド作業に入る前に、
ファイルディスクリプタ制限を引き上げておく
ことを前提とします。

設定方法の詳細は後述しますが、
「何か問題が起きたときに都度コマンドで対応する」
という割り切りでも構いません。

重要なのは、
この制限が存在することを
事前に知っておくことです。

### 4.2.4 事前準備の考え方

ここまで挙げた前提条件は、
ビルドそのものを難しくするものではありません。

しかし、
これらを知らないまま進めると、
「なぜ動かないのか分からない」
という状態に陥りやすくなります。

本章では、
環境構築を完璧に整えることよりも、
後戻りしないための地ならしを目的とします。

次節では、
実際にリポジトリを取得し、
ビルド対象を確認したうえで、
具体的なビルド手順へ進みます。

## 4.3 リポジトリ構成とビルド対象

### 4.3.1 Symbol モノレポの全体像

Symbol の公式リポジトリは、
ノード本体や Rest API を含む
モノレポ構成になっています。

本書では、その中でも
以下の 2 つのコンポーネントのみを対象とします。

- `client/catapult`
- `client/rest`

ただし、
両者の扱いは大きく異なります。

### 4.3.2 `client/catapult`

`client/catapult` は、
Symbol ノードの中核となるコンポーネントです。

ブロックの検証、
P2P ネットワークへの参加、
チェーン状態の管理など、
ノードとしての本体機能がすべて含まれています。

本章で扱う「ビルド」とは、
この `client/catapult` を
C++ でビルドすることを指します。

Peer ノード、API ノード、Voting ノードといった役割は、
同じビルド成果物を、
設定によって使い分ける形になります。

### 4.3.3 `client/rest`

`client/rest` は、
Symbol の Rest API を提供するコンポーネントです。

このコンポーネントは
JavaScript（Node.js）で実装されており、
C++ コンポーネントである `client/catapult` のような
**ビルド工程は存在しません**。

Node.js の実行環境さえ整っていれば、
ソースを配置し、依存パッケージを導入することで動作します。

そのため、本章で扱っている
「ビルド作業」の対象には含めません。

`client/rest` のセットアップや起動方法については、
後の章（API の章）で、
実行環境や構成の違いを踏まえたうえで
改めて説明します。

ここでは、

「Rest は _ビルド対象ではなく、実行・構成の対象である_」

という点だけを押さえておけば十分です。

### 4.3.4 本書で扱う構成の考え方

本章では、

- `client/catapult` をビルドし
- Peer ノードとして起動できる状態を作る

ところまでを対象とします。

API ノード構成や Voting ノード構成については、
同じビルド成果物を前提に、
後続章で設定や役割の違いとして扱います。

### 4.3.5 ここまでの整理

ここまでの内容を整理すると、次のとおりです。

- Symbol リポジトリはモノレポ構成である
- ビルドが必要なのは `client/catapult` のみ
- `client/rest` はビルド不要で、本章では扱わない

この前提を共有したうえで、
次節では、
`client/catapult` を最小構成でビルドする手順
に進みます。

## 4.4 実際のビルド手順（最小構成）

本節では、Symbol モノレポ内の `client/catapult` を対象に、最小構成でビルドして実行ファイルを生成します。
なお、現時点の 最新安定バージョンは 1.0.3.9 です。

ここで行うのは catapult のビルドのみです。
`client/rest` は Node.js で動作し ビルド不要のため、セットアップは後の章（API の章）で扱います。

### 4.4.1 必要なパッケージをインストール

まずはビルドに必要なパッケージを導入します。

```bash
sudo apt update
sudo apt upgrade -y
sudo apt -y install git gcc g++ curl libssl-dev libgtest-dev ninja-build pkg-config cmake
```

### 4.4.2 Symbol のソースをクローン

モノレポを取得し、対象バージョンのブランチを指定してクローンします。
保存場所はホームディレクトリ（`~/symbol`）を想定します。

```bash
git clone https://github.com/symbol/symbol.git -b client/catapult/v1.0.3.9
```

### 4.4.3 依存パッケージをビルド

`installDepsLocal.py` を使って、catapult のビルドに必要な依存物を `deps` 配下に構築します。

```bash
cd ~/symbol/client/catapult
```

初回は `--download` 付きで実行します。

```bash
PYTHONPATH="../../jenkins/catapult/" \
  python3 "../../jenkins/catapult/installDepsLocal.py" \
  --target "./deps" \
  --versions "../../jenkins/catapult/versions.properties" \
  --build \
  --download
```

ビルド中にエラーが出た場合は、原因を解消して再実行します。
再実行時は `--download` を外して構いません。

### 4.4.4 Symbol サーバー（catapult）をビルド

ビルド用ディレクトリを作成します。

```bash
mkdir -p build && cd build
```

次に `cmake` を実行します。ここでは時間短縮のため、テスト用バイナリのビルドを無効にします。

```bash
BOOST_ROOT="$(realpath ../deps/boost)" cmake .. \
  -DENABLE_TESTS=OFF \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH="$(realpath ../deps/facebook);$(realpath ../deps/google);$(realpath ../deps/mongodb);$(realpath ../deps/zeromq);$(realpath ../deps/openssl)" \
  -GNinja
```

以下の警告が出ることがありますが、警告なので無視して問題ありません（ビルドは継続できます）。

```bash
CMake Warning (dev) ... Policy CMP0144 is not set ...
Environment variable BOOST_ROOT is set to: ...
For compatibility, find_package is ignoring the variable, ...
This warning is for project developers.  Use -Wno-dev to suppress it.
```

ビルドを開始します。

```bash
ninja publish && ninja
```

### 4.4.5 インストール

ビルド成果物を `/usr/local/catapult` に配置します。
`~/symbol/client/catapult` に戻り、インストール用スクリプトを作成します。

```bash
cd ~/symbol/client/catapult
vi symbol_install.sh
```

```bash
#!/bin/bash
set -e

rm -rf /usr/local/catapult
mkdir -p /usr/local/catapult/bin
mkdir -p /usr/local/catapult/lib
mkdir -p /usr/local/catapult/deps

# bin
cp build/bin/catapult* /usr/local/catapult/bin

# lib
cp build/bin/lib* /usr/local/catapult/lib

# dependence lib
cp -r deps/boost/lib/*.so* /usr/local/catapult/deps
cp -r deps/facebook/lib/*.so* /usr/local/catapult/deps
cp -r deps/mongodb/lib/*.so* /usr/local/catapult/deps
cp -r deps/openssl/*.so* /usr/local/catapult/deps
cp -r deps/openssl/engines-3 /usr/local/catapult/deps
cp -r deps/openssl/ossl-modules /usr/local/catapult/deps
cp -r deps/zeromq/lib/*.so* /usr/local/catapult/deps
```

実行権限を付けて実行します。

```bash
chmod +x symbol_install.sh
sudo ./symbol_install.sh
```

### 4.4.6 外部依存ライブラリの扱い（ldconfig を使用）

catapult は、
ビルド時に使用した外部依存ライブラリを
`deps` ディレクトリにまとめています。

これらのライブラリを実行時に参照させる方法はいくつかありますが、
サーバーとして安定運用する場合は、
動的リンカの検索パスとして登録する方法が最も安全です。

本書では、
環境変数 `LD_LIBRARY_PATH` ではなく、
`ldconfig` を使用して
全ユーザー共通のライブラリ参照設定を行います。

#### ライブラリパスの登録

以下のコマンドで、
`/usr/local/catapult/deps` を
動的リンカの検索対象に追加します。

```bash
echo "/usr/local/catapult/deps" | sudo tee /etc/ld.so.conf.d/catapult.conf
sudo ldconfig
```

これにより、

- 実行ユーザーに依存しない
- systemd から起動しても確実に動作する

状態になります。

実行ファイルへのパス設定

実行ファイルについては、
`PATH` に追加しておくと便利です。

```bash
vi ~/.bashrc
```

末尾に以下を追加します。

```bash
export PATH="/usr/local/catapult/bin:$PATH"
```

反映します。

```bash
source ~/.bashrc
```

※ systemd から起動する場合は、
unit ファイル側で `PATH` を指定しても構いません。

### 4.4.7 実行確認

以下のコマンドを実行し、
ヘルプが表示されれば、
ビルドおよびライブラリ設定は成功です。

```bash
catapult.tools.address --help
```

#### 補足：この方法を採用する理由

この方法では、

- `.bashrc` に依存しない
- ノード用ユーザーでの実行にそのまま対応できる
- 環境差による起動失敗が起きにくい

という利点があります。

patchelf による RPATH 設定も可能ですが、
本書では サーバー運用を前提とし、
より標準的な方法として ldconfig を採用します。

## 4.5 よくあるビルドエラーと割り切り方

Symbol ノードのビルドは、
手順通りに進めれば難しい作業ではありません。

一方で、
環境差やネットワーク状況によって、
いくつか 起こりやすいトラブル があります。

本節では、
すべてを完全に解消することは目指しません。
「どこまで気にするべきか」
「どこで割り切って先へ進むか」
という判断軸を整理します。

### 4.5.1 依存パッケージのダウンロード失敗

`installDepsLocal.py` の実行中に、
外部ライブラリのダウンロードで失敗することがあります。

特に多いのは、

- boost のダウンロード失敗
- 一時的なネットワークエラー

です。

この場合、
ビルドスクリプト自体が壊れているわけではありません。
単純に取得先の問題であることがほとんどです。

重要なのは、

> 一度失敗したからといって、環境全体が壊れたと考えないこと

です。

### 4.5.2 依存パッケージの再ビルド問題

依存ビルドの途中でエラーが発生した場合、
原因を修正したあとに
再実行することになります。

このとき、

- 毎回 `--download` を付ける必要はありません
- 既に取得済みのファイルは再利用されます

再実行が前提の設計なので、
途中失敗は想定内と考えて構いません。

### 4.5.3 cmake の警告と無視してよい線引き

`cmake` 実行時には、
さまざまな警告が表示されることがあります。

代表的なのが、

- Policy に関する警告
- find_package に関する警告

です。

これらの多くは、

- 将来の互換性
- 開発者向けの注意喚起

であり、
現時点のビルド成否には影響しません。

> 警告が出た = 失敗ではありません。

明確な `Error` が出ていなければ、
まずは先へ進んで構いません。

### 4.5.4 ビルドが途中で止まる（リソース不足）

ビルド中に、

- プロセスが強制終了される
- マシンが極端に重くなる

といった症状が出る場合、
メモリ不足や CPU 枯渇が原因のことがあります。

特に、

- 小規模な VPS
- 並列ビルド（`-j`）を指定している場合

は注意が必要です。

この場合は、

- 並列数を減らす
- 一時的にスワップを増やす

といった対処で回避できます。

### 4.5.5 ファイルディスクリプタ制限による問題

ビルド自体は成功しても、
起動時に問題が出るケースがあります。

その一因が、
ファイルディスクリプタ制限です。

設定が低いままだと、

- 起動直後に落ちる
- 接続が増えた途端に不安定になる

といった症状が発生します。

この問題は、
ビルド手順の誤りではありません。

> 運用前に一度設定を見直すべき項目

として認識しておけば十分です。

### 4.5.6 「直す」より「切り分ける」

ビルド時のトラブルに直面すると、
すべてを完璧に解決したくなりがちです。

しかし、実運用では、

- 再実行すれば通るもの
- 無視してよい警告
- 後段の設定で吸収される問題

も少なくありません。

本章で扱ったトラブルは、
多くが 環境起因であり、
catapult のロジックそのものとは無関係です。

> 原因を特定できたら、必要以上に深追いしない

これが、
ビルドを通過点として扱うための
いちばん現実的な割り切り方です。

# 第5章 ノードの設定と起動準備

第4章では、
Symbol ノード本体（`catapult`）をビルドし、
実行可能な状態まで準備しました。

この時点で得られているのは、

- catapult の実行ファイル
- 依存ライブラリ
- 実行環境として成立する土台

までです。

しかし、
これだけではノードはまだ起動できません。

Symbol ノードをネットワークに参加させるためには、

- 実行ユーザーの整理
- ノード設定ファイルの作成
- 通信に用いる証明書の作成

といった 運用前提の準備 が必要になります。

本章では、
これらを「難しい設定」としてではなく、
順番に揃えていく起動準備として扱います。

## 5.1 実行ユーザーとディレクトリ設計

まず、
ノードを どのユーザーで実行するか を決めます。

Symbol ノードは、
長時間常駐し、外部ネットワークと通信するプロセスです。
そのため、本書では、

> 専用のノード用ユーザーで実行する

ことを前提とします。

これは特別な制約ではなく、
一般的なサーバー運用と同じ考え方です。

### 5.1.1 ノード用ユーザーの作成

以下の例では、
`catapult` という専用ユーザーを作成します。

```bash
sudo useradd -r -m -s /usr/sbin/nologin catapult
```

- ログインシェルは無効化
- ノード実行専用のユーザー

という最小構成です。

### 5.1.2 ディレクトリ構成の考え方

本書では、
catapult 本体は `/usr/local/catapult` に配置済みとし、
設定ファイルやデータは別に管理します。

代表的な構成例は以下のとおりです。

```text
/usr/local/catapult/
  ├─ bin/
  ├─ lib/
  └─ deps/

/var/lib/catapult/
  ├─ data/
  └─ state/

/etc/catapult/
  ├─ config/
  └─ certs/
```

- 実行ファイル：`/usr/local/catapult`
- 永続データ：`/var/lib/catapult`
- 設定・証明書：`/etc/catapult`

役割を分けておくことで、

- 再インストール時にデータを保持できる
- 設定や証明書の権限を厳密に管理できる

といった利点があります。

### 5.1.3 権限の設定

ノード用ユーザーが必要な範囲だけに
アクセスできるよう、
ディレクトリの所有者を変更します。

```bash
sudo mkdir -p /var/lib/catapult
sudo mkdir -p /etc/catapult

sudo chown -R catapult:catapult /var/lib/catapult
sudo chown -R catapult:catapult /etc/catapult
```

`/usr/local/catapult` は
実行用として `root` 管理のままでも構いません。

## 5.2 証明書の作成（TLS）

Symbol ノードは、
P2P 通信および各種内部通信に
TLS 証明書を使用します。

そのため、
ノードを起動する前に、
CA 証明書とノード証明書を作成する必要があります。

本書では、

- OpenSSL を使用
- ed25519 鍵を使用
- ノード自身で CA を作成
- 証明書と秘密鍵は `/etc/catapult/certs` に配置する

という、
最小構成かつ実運用に耐える方法を採用します。

### 5.2.1 作業ディレクトリの準備

証明書は設定情報の一部として扱うため、
`/etc/catapult/certs` 配下で作業します。

```bash
sudo mkdir -p /etc/catapult/certs
sudo chown -R catapult:catapult /etc/catapult/certs
cd /etc/catapult/certs
```

以降の作業は、
`root` ではなくノード用ユーザー（`catapult`）で行う
ことを前提とします。

### 5.2.2 CA 用ディレクトリの初期化

OpenSSL の CA 機能を使用するため、
最低限のファイルを用意します。

```bash
mkdir newcerts
touch index.txt
echo 1000 > serial
```

### 5.2.3 CA 秘密鍵の作成

CA 用の秘密鍵を ed25519 で作成します。

```bash
openssl genpkey -algorithm ed25519 -out ca.key.pem
chmod 600 ca.key.pem
```

この鍵は CA の中核となる秘密情報 です。
外部に漏れないよう、
必ずパーミッションを制限します。

### 5.2.4 CA 証明書の作成

CA 用の設定ファイルを作成します。

```bash
vi ca.cnf
```

```conf
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = .
database          = $dir/index.txt
new_certs_dir     = $dir/newcerts
serial            = $dir/serial
private_key       = $dir/ca.key.pem
certificate       = $dir/ca.crt.pem
default_md        = sha256
policy            = policy_any
x509_extensions   = v3_ca

[ policy_any ]
commonName        = supplied

[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
CN = Symbol CA

[ v3_ca ]
basicConstraints = critical,CA:true
keyUsage = critical,keyCertSign,cRLSign
```

CA 証明書を作成します。

```bash
openssl req -new -x509 -days 7300 \
  -key ca.key.pem \
  -out ca.crt.pem \
  -config ca.cnf
```

### 5.2.5 ノード秘密鍵の作成

次に、ノード用の秘密鍵を作成します。

```bash
openssl genpkey -algorithm ed25519 -out node.key.pem
chmod 600 node.key.pem
```

### 5.2.6 ノード証明書要求（CSR）の作成

ノード用の設定ファイルを作成します。

```bash
vi node.cnf
```

```conf
[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
CN = Symbol Node

[ v3_node ]
basicConstraints = CA:false
keyUsage = digitalSignature
extendedKeyUsage = serverAuth,clientAuth
```

CSR を作成します。

```bash
openssl req -new \
  -key node.key.pem \
  -out node.csr.pem \
  -config node.cnf
```

### 5.2.7 ノード証明書の発行

CA を使って、
ノード証明書を署名します。

```bash
openssl ca \
  -config ca.cnf \
  -extensions v3_node \
  -days 375 \
  -in node.csr.pem \
  -out node.crt.pem \
  -batch
```

### 5.2.8 フルチェーン証明書の作成

Symbol ノードでは、
ノード証明書と CA 証明書を結合した
フルチェーン証明書を使用します。

```bash
cat node.crt.pem ca.crt.pem > node.full.crt.pem
```

最終的に必要となるファイルは以下です。

- `node.key.pem`（ノード秘密鍵）
- `node.full.crt.pem`（フルチェーン証明書）
- `ca.crt.pem`（CA 証明書）

### 5.2.9 権限の最終確認

証明書ディレクトリ全体を、
ノード用ユーザーのみが参照できるようにします。

```bash
chmod 700 /etc/catapult/certs
chmod 600 *.pem
```

### 補足：CA 秘密鍵の扱いについて

CA の秘密鍵（`ca.key.pem`）は、
Symbol ノードにおいて 特別な意味を持つ鍵 です。

この鍵は、
ノード証明書を発行できる唯一の鍵であり、
役割としては ノードのメインアカウントに相当します。

そのため、

- 紛失すると証明書の再発行ができなくなります
- 他者に渡ると、なりすまし証明書を発行される可能性があります

取り扱いには十分注意してください。

一方で、
ノードの通常運用（通信）において
CA の秘密鍵は使用されません。

ノードが起動時および通信時に使用するのは、

- ノード秘密鍵（`node.key.pem`）
- ノード証明書（`node.full.crt.pem`）

のみです。

そのため、運用方針によっては、

> ノード証明書の発行後に `ca.key.pem` を安全な場所に退避、あるいは削除する

という選択も可能です。

この場合、
証明書の更新や再発行を行う際には、
CA 秘密鍵を復元するか、
CA から作り直す必要があります。

### 補足：更新と再作成について

ノード証明書には有効期限があります。
期限が近づいた場合は、

ノード秘密鍵を保持したまま再署名する

または鍵ごと作り直す

いずれの方法でも問題ありません。

CA 鍵を保持している限り、
再発行は比較的容易です。

<!-- もう少し具体的にコマンドを交えて書いたほうが良い -->

## 5.3 ネメシスブロックと設定ファイルの配置（Peer ノード / testnet）

本節では、
テストネット（testnet） を使用して
Peer ノードを起動するための設定を行います。

テストネットは、

- 実資産を使用しない
- ノード運用の挙動はメインネットと同等
- 設定ミスや再構築を気軽に試せる

という理由から、
最初の構築手順として最適です。

> なお、本節で使用する設定をmainnet 用に切り替えるのは容易であり、該当箇所についてはその都度説明します。

### 5.3.1 ネメシスブロックと設定ファイルの取得（testnet）

Symbol では、
ネットワークごとに必要なネメシスブロックおよび
Peer ノード用設定ファイルが配布されています。

ここでは testnet を使用します。

```
curl -OL https://github.com/symbol/symbol/releases/download/client%2Fcatapult%2Fv1.0.3.7/configuration-testnet.zip
unzip configuration-testnet.zip
rm configuration-testnet.zip shoestring.ini README.md
```

展開すると、以下のディレクトリが作成されます。

- `seed/`
  テストネット用ネメシス（ジェネシス）ブロック
- `resources/`
  Peer ノード用の各種設定ファイル

補足：mainnet を使用する場合

mainnet を使用する場合は、
取得する ZIP を以下に変更するだけです。

```
configuration-mainnet.zip
```

設定ファイルの構造や編集内容は同一です。

5.3.2 配置先ディレクトリ

本書では、
FHS に沿って以下のように配置します。

```
/etc/catapult/
  └─ config/
      └─ resources/

/var/lib/catapult/
  ├─ seed/
  └─ data/
```

配置を行います。

```
sudo mkdir -p /etc/catapult/config
sudo mkdir -p /var/lib/catapult/seed
sudo mkdir -p /var/lib/catapult/data

sudo cp -r resources /etc/catapult/config/
sudo cp -r seed/* /var/lib/catapult/seed/

sudo chown -R catapult:catapult /etc/catapult
sudo chown -R catapult:catapult /var/lib/catapult
```

### 5.3.3 ノード情報の設定（Peer / testnet）

ノード固有の情報を設定するため、
`resources/config-node.properties` を編集します。

```
vi /etc/catapult/config/resources/config-node.properties
```

```
[localnode]

host = <YOUR_NODE_IP_OR_HOSTNAME>
friendlyName = <YOUR_FRIENDLY_NAME>
version =
roles = Peer
```

- `host`
  ノードの IP アドレスまたはホスト名
- `friendlyName`
  ノード名（英数字のみ）
- `roles`
  本章では Peer のみを指定します

### 5.3.4 初期同期を安定させる設定

テストネットでも、
初回同期を安定させるために
以下の調整を行っておくと安心です。

```
maxChainBytesPerSyncAttempt = 10MB
blockDisruptorMaxMemorySize = 1000MB
```

### 5.3.5 ハーベストの設定

ハーベストの設定を`resources/config-harvesting.properties`に設定します。

- `harvesterSigningPrivateKey`: bootstrap では remote と呼ばれるアカウントの秘密鍵を設定します
- `harvesterVrfPrivateKey`: VRF アカウントの秘密鍵
- `enableAutoHarvesting`: true
- `maxUnlockedAccounts`: 委任を受け入れる最大値
- `delegatePrioritizationPolicy`: 委任者の最大を超えたときの追い出し挙動(Importance または Age)
- `beneficiaryAddress`: ハーベスト報酬の受け取りアドレス

```properties:resources/config-harvesting.properties
[harvesting]

harvesterSigningPrivateKey = <HARVESTER_SIGNING_PRIVATE_KEY>
harvesterVrfPrivateKey = <HARVESTER_VRF_PRIVATE_KEY>

enableAutoHarvesting = true
maxUnlockedAccounts = 100
delegatePrioritizationPolicy = Importance
beneficiaryAddress = <BENEFICIARY_ADDRESS>
```

新規にノードを立てる場合、`harvesterSigningPrivateKey`と`harvesterVrfPrivateKey`は、未使用の新しいアカウントを設定します。  
以下のコマンドで、テストネット用のアカウント 2 つが作成出来ます。

```bash:bash
catapult.tools.addressgen -n testnet -c 2
```

ノードのメインアカウントでハーベストする場合はノード立ち上げ後、AccountKeyLink と VRFKeyLink トランザクションを発行する必要があります。

#### ハーベストキーリンク

<!-- TODO:
キーリンク（AccountKeyLink / VRFKeyLink / VotingKeyLink）の実装方法を追記する。
symbol-cli への依存は避け、SDK ベースのコードまたは独自ツールを前提とする。
実装は別リポジトリで管理し、本文では設計方針のみ扱う。
-->

<!-- `symbol-cli`がメンテナンスされていなくて使用できない所もある。デスクトップウォレットを使ってリンクさせる方法に切り替える。それか、コード書くか。 -->

<!-- メインアカウントでハーベストを行う場合は、キーリンクが必要です。
キーリンクトランザクションを発行するために、`symbol-cli`をインストールします。

```bash:bash
npm i -g symbol-cli
```

インストールが終わったらプロファイルを設定します。
`--url http://localhost:3000`はトランザクションをアナウンスするノードなので、立ち上げ前のローカルではなく別の稼働中のノードを指定してください。

```bash:bash
symbol-cli profile import --network MAIN_NET --url http://localhost:3000 --default
```

```plaintext
✔ Enter a profile name: … MainNetProfile
✔ Select an import type: › PrivateKey
✔ Enter your wallet password: … ********
✔ Enter your account private key: … ****************************************************************
```

- Enter a profile name: 任意のプロファイル名を入力
- Select an import type: PrivateKey を選択
- Enter your wallet password: プロファイル保護のために任意のパスワードを入力
- Enter your account private key: ノードのメインアカウントの**秘密鍵**を入力

プロファイルは`~/symbol-cli.config.json`に保存されます。

##### リモートキーリンク

```bash:bash
symbol-cli transaction accountkeylink --sync --action Link \
           --max-fee 20000 --mode normal
```

```plaintext
✔ Enter your wallet password: … ********
✔ Enter the public key of the remote account:  … ****************************************************************
```

- Enter your wallet password: プロファイルのパスワードを入力
- Enter the public key of the remote account: harvesterSigningPrivateKey に設定したアカウントの**公開鍵**を入力

##### VRF キーリンク

```bash:bash
symbol-cli transaction vrfkeylink --sync --action Link \
           --max-fee 20000 --mode normal
```

```plaintext
✔ Enter your wallet password: … ********
✔ Enter the public key to link:  … ****************************************************************
```

- Enter your wallet password: プロファイルのパスワードを入力
- Enter the public key to link: harvesterVrfPrivateKey に設定したアカウントの**公開鍵**を入力 -->

### 5.3.6 各ディレクトリの場所を設定

各ディレクトリの場所が`resources/config-user.properties`に設定されています。基点は`catapult.server`を起動した時の作業ディレクトリです。

```properties:resources/config-user.properties
[account]

enableDelegatedHarvestersAutoDetection = true

[storage]

seedDirectory = /var/lib/catapult/seed
certificateDirectory = /etc/catapult/certs
dataDirectory = /var/lib/catapult/data/rocks
pluginsDirectory = /usr/local/catapult/lib
votingKeysDirectory = /etc/catapult/votingkeys
```

### 5.3.7 接続ピアリスト（testnet）

起動時に接続する Peer ノード一覧は
`resources/peers-p2p.json` に設定します。

テストネット用の Peer は、
以下のページから確認できます。

testnet:
https://peers-p2p.harvestasya.com/peers-p2p/testnet

mainnet:
https://peers-p2p.harvestasya.com/peers-p2p/mainnet

テストネットでは Peer の入れ替わりも多いため、
最初は少数で構いません。

## 5.4 ポートの開放

できれば 7900 ポートを開放しておいて下さい。

開放しなくても動作はしますが、片方向の同期になるので若干フォーク耐性が下がります。

```bash:bash
sudo ufw allow 7900
```

# 第6章：ノードの起動と動作確認

## 6.1 コマンドラインからノードを起動する

```bash
cd /var/lib/catapult
catapult.server ./etc/catapult
```

引数は設定ファイルのある場所を指定します。

## 6.1.1 同期できているかログの確認

起動するとログがコンソールに流れるので、以下のログが出るか確認する。

```plaintext
<info> (disruptor::ConsumerDispatcher.cpp@44) completing processing of element 1 (360 blocks (heights 2 - 361) [7B055CD0] from Remote_Pull with size 143KB 472B), last consumer is 0 elements behind
```

このログが継続して出力され、
ブロックの高さが増え続けている状態であれば、
Peer ノードとして正常に同期しています。

エラーが出ればメッセージを確認して解消してください。ディレクトリの指定ミスや権限がないなどが原因です。

### 6.1.2 停止方法

停止は、`Ctrl`+`C` です。
ただし、処理終了中に再度 `Ctrl`+`C` するとデータが破損するので注意。

### 6.1.3 データ破損時の復旧方法

異常終了した場合は、ブロックデータディレクトリに `lock` ファイルが残ります。このファイルがある場合は、起動しません。削除してもデータが破損していて起動に失敗することが多いです。

以下の2つの方法を順にしましょう。2つと言っても2つ目は諦めですが。。。

1. ブロックデータディレクトリにlockファイルが残っている場合は、`catapult.recovery` を実行して修復を試みる

   ```bash
   catapult.recovery ./etc/catapult
   ```

1. それでもダメな場合は、諦めてブロックデータを削除して再同期

## 6.2 サービス化する

```bash:bash
sudo vi /etc/systemd/system/symbol.service
```

<!-- TODO: lockファイルのディレクトリ確認する -->

```service:/etc/systemd/system/symbol.service
[Unit]
Description=Symbol Peer Node (catapult.server)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=catapult
Group=catapult
WorkingDirectory=/var/lib/catapult/run

# 依存ライブラリ
Environment="LD_LIBRARY_PATH=/usr/local/catapult/deps"

# lock が残ってる場合だけ recovery してから起動（1ユニットで完結）
ExecStartPre=/bin/sh -c 'test -f /var/lib/catapult/data/rocks/server.lock && /usr/local/catapult/bin/catapult.recovery . || true'

ExecStart=/usr/local/catapult/bin/catapult.server .
KillSignal=SIGINT
Restart=on-failure
RestartSec=2
TimeoutStopSec=300

# FD と権限
LimitNOFILE=65536
UMask=077

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### サービスをリロード

```bash
sudo systemctl daemon-reload
```

### サービスを有効化

```bash
sudo systemctl enable symbol
```

### サービスを開始

```bash
sudo systemctl start symbol
```

### ログの確認

symbol サービスのみを参照します。最新から参照できるよう`-r`オプションを付けます。

```bash
sudo journalctl -u symbol -r
```

リアルタイムで確認したい場合は`-f`オプションを付けます。

```bash
sudo journalctl -u symbol -f
```

さらに色を付けたい場合は、`-o cat`オプションを付けます。

```bash
sudo journalctl -u symbol -f -o cat
```

### サービスを停止

```bash:
sudo systemctl stop symbol
```

# 第7章 Light-API

## 7.1 Peer ノード運用の限界と light-api の役割

第6章までで、Peer ノードは起動し、同期も進んでいるはずです。
しかし、Peer ノード単体での運用には、次のような課題があります。

- 同期状態の判断がログ依存になる
- 外部から「正常に見えているか」を確認できない
- 高さ・チェーン状態・ノード情報を即座に取得できない

Peer ノードはネットワークを構成する主体であり、
観測・提供用の API は本来の役割ではありません。

そのため、Peer だけで運用を続けると、

> 「動いている“気がする”が、確信が持てない」

という状態に陥りやすくなります。

この問題を解消するために、本章では light-api を追加します。

## 7.2 light-api の構成と制約（Mongo を使わない理由）

light-api は、MongoDB を使用しない REST API ノード構成です。

特徴

- MongoDB 不要
- Broker 不要
- Peer ノードから直接状態を取得
- 参照系 API のみ提供

できること

- ノード情報の取得
- チェーンの高さ・状態確認
- 同期状況の確認

できないこと

- トランザクション履歴の検索
- アカウント履歴の保持
- 高度なフィルタリング
- WebSocket による簡易通知

本章では、これを欠点とは捉えません。

light-api はあくまで、

> 「Peer ノードが正しく動いているかを確認するための観測用 API」

として導入します。

また、ノード情報も参照できるため委任ハーベストも受け付けることができます。

## 7.3 ディレクトリ配置（FHS 準拠・Peer との関係）

本書では、Peer ノードと同様に FHS を意識した配置を採用します。

例：light-api 配置

```
/usr/local/lib/symbol/light-api/
  ├─ bin/
  ├─ resources/
  └─ config/

/etc/symbol/light-api/
  ├─ api-node.properties
  ├─ websocket.properties
  └─ logging.properties

/var/lib/symbol/light-api/
  ├─ state/
  └─ cache/
```

実行バイナリ：`/usr/local/lib`

設定ファイル：`/etc`

状態・一時データ：`/var/lib`

Peer ノードとはプロセスも設定も明確に分離します。

## 7.4 Light-APIの設置＆設定ファイル

リポジトリから rest をコピーします。

```bash:bash
cp -r symbol/client/rest /opt/symbol-node
cd /opt/symbol-node/rest
```

Light-APIの設定を変更

```bash:bash
vi resources/rest.light.json
```

```diff:resources/rest.light.json
{
    "network": {
        "name": "testnet",
        "description": "catapult public test network"
    },

    "port": 3000,
-    "protocol": "HTTPS",
+    "protocol": "HTTP",
    "sslKeyPath": "",
    "sslCertificatePath": "",
    "crossDomain": {
        "allowedHosts": ["*"],
        "allowedMethods": ["GET"]
    },

    "apiNode": {
        "host": "127.0.0.1",
        "port": 7900,
        "timeout": 1000,
-        "tlsClientCertificatePath": "/",
-        "tlsClientKeyPath": "/",
-        "tlsCaCertificatePath": "/"
+        "tlsClientCertificatePath": "../target/nodes/node/cert/node.crt.pem",
+        "tlsClientKeyPath": "../target/nodes/node/cert/node.key.pem",
+        "tlsCaCertificatePath": "../target/nodes/node/cert/ca.cert.pem"
    },

    "throttling": {
        "burst": 20,
        "rate": 5
    },

    "logging": {
        "console": {
            "formats": ["colorize", "simple"],

            "level": "verbose",
            "handleExceptions": true
        },
        "file": {
            "formats": ["prettyPrint"],

            "level": "verbose",
            "handleExceptions": true,

            "filename": "catapult-rest.log",
            "maxsize": 20971520,
            "maxFiles": 100
        }
    },

    "deployment": {
        "deploymentTool": "",
        "deploymentToolVersion": "",
        "lastUpdatedDate": ""
    }
}
```

#### 依存 npm パッケージをインストール

```bash:bash
npm i
```

### light-rest の確認

light-rest を一旦起動します。

```bash:bash
npm run start-light resources/rest.light.json
```

もう一つコンソールを立ち上げて rest が正常に動作しているか確認します。

```bash:bash
curl -s http://127.0.0.1:3000/chain/info | jq
curl -s http://127.0.0.1:3000/node/info | jq
curl -s http://127.0.0.1:3000/node/peers | jq
curl -s http://127.0.0.1:3000/node/server | jq
curl -s http://127.0.0.1:3000/node/unlockedaccount | jq
```

<!-- `trustedHosts`と`localNetworks`の設定が必要 -->

## 7.5 systemd サービスとしての light-api

Peer ノードと同様に、light-api も systemd 管理とします。

```
[Unit]
Description=Symbol Light Rest Gateway
Requires=network.target
BindsTo=symbol.service

[Service]
Type=idle
ExecStart=/home/ユーザー名/.volta/bin/npm run start-light resources/rest.light.json
User=ユーザー名
Group=ユーザー名
WorkingDirectory=/opt/symbol-node/rest
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

light-api は Peer に依存はしますが弱い依存なため順番は特に気にする必要はありません。

## 7.6 Peer + light-api 構成の運用ポイント

この構成は次のような用途に向いています。

- ノードの初期構築確認
- ハーベスト用
- 外形監視（curl / simple monitor）

一方で、

- 公開 API として提供する
- 外部アプリから叩かせる

といった用途には 向きません。

委任ハーベストを募るだけであれば、これで十分でしょう。現状、フルRestのほうがノードリスト上目立ちますが、運用コストを考えると Peer + light-api がベストです。

<!-- ## 7.7 フル REST API への布石

light-api を導入すると、

- ノード状態の把握
- Peer の健全性確認
- systemd 管理の一貫性

が確立されます。

次章では、この構成を土台として、

- MongoDB
- Broker
- フル REST API

をそれぞれ独立したサービスとして追加していきます。
ファイルIOが増えるため、NVMe SSD を推奨します。SSD でも動きますが、動機が遅れたりプチフォークが頻出する所謂クソノードになりやすいです。 -->

# 第8章 Peer + API の起動と動作確認

## 8.1 Peer + API 構成とは何か（light-api との違い）

Peer と API の二つのノードが起動することから、Dual ノードと呼ばれます。
現在、一番多い形態の構成となっています。

コンポーネントは、Peer + Light-API のときにより以下のコンポーネントが追加されます。

- Broker
- MongoDB

Peer + Light-API は、ブロックの検証まででした。Dual ノードになると、情報の提供になります。ウォレットなどのアプリが情報を取得に接続してきます。

light-api は「見るための API」でしたが、
Peer + API 構成では「他者が使う API」になります。

この違いにより、
ノードは単に同期していれば良い状態から、
常に整合性を保ち続ける必要がある状態に変わります。

## 8.2 全体構成とプロセス関係

```
Peer (catapult.server)
  ↓ file spool
Broker (catapult.broker)
  ↓
MongoDB
  ↑
Rest Gateway
```

ファイルIOが増え、MongoDBへの書き込みが遅延するとファイルスプールがつまり瞬間的にファイルディスクリプタが枯れBrokerが落ちることがあります。Peer、Brokerは疎結合なのでBrokerが落ちてもPeerは動き続けます。そうなるとPeerの持つブロックの状態とMongoDBが持つ状態に差ができ、修復が不可能になり再同期が必要となります。

この構成では、
Peer が正常でも、Broker や MongoDB の状態次第で
API とチェーン状態が乖離することがあります。

この乖離は自然に修復されることはなく、
多くの場合は MongoDB の再同期が必要になります。

というように、運用コストがPeer + Light-APIより増加します。

## 8.3 エクステンション構成（server / broker / recovery）

### 8.3.1 server エクステンション

[extensions]

extension.filespooling = true
extension.partialtransaction = true
...

light-api との差分

filespooling が 必須

server は「書き出す側」

### 8.3.2 broker エクステンション

[extensions]

extension.addressextraction = true
extension.mongo = true
extension.zeromq = true
extension.hashcache = true

順序が重要な理由

zeromq が REST と結びつく点

### 8.3.3 recovery エクステンション

[extensions]

extension.addressextraction = true
extension.mongo = true
extension.zeromq = true
extension.filespooling = false
extension.hashcache = true

なぜ filespooling を切るのか

recovery の責務は「復旧のみ」

## 8.4 データベース設定（Mongo 接続）

databaseUri = mongodb://127.0.0.1:27017

loopback 限定の意味

ネットワークに出す必要がない理由

Mongo を 外に出す設計は推奨しない

## 8.5 API Peer リストの作成

cp resources/peers-p2p.json resources/peers-api.json

なぜ同じでよいのか

API Peer = 信頼済み Peer という前提

## 8.6 MongoDB の導入と初期化

### 8.6.1 MongoDB のインストール

（提示いただいた手順そのままでOK）

GPG

apt repo

mongodb-org

### 8.6.2 DB ディレクトリ設計

/opt/symbol-node/data/mongo

catapult データと分離する理由

### 8.6.3 初期化手順

mongosh catapult mongoDbPrepare.js

ここを忘れると REST が起動しない

よくあるトラブルとして明記する価値あり

## 8.7 REST Gateway の構築

### 8.7.1 rest の配置と npm install

cp -r ~/symbol/client/rest /opt/symbol-node
npm i

light-api と 同じだが別物

rest.light.json を使わない理由

### 8.7.2 rest.json の編集方針

ここは 全文掲載で正解です。

理由：

REST は再構築時にここだけ見たい

diff だと文脈が切れる

＋ コメントで：

// light-api では不要だった設定

と入れるのがベスト。

## 8.8 systemd サービス設計（重要）

### 8.8.1 MongoDB

forking

pidfile

tmpfiles.d

→ 運用ノウハウとしてかなり価値が高い

### 8.8.2 Rest Gateway

npm + systemd

broker / db との依存関係

### 8.8.3 Recovery

oneshot

lock ファイル検知

自動復旧の最小単位

### 8.8.4 Broker

server との関係

停止時に REST / Mongo を巻き取る設計

👉 ここは「設計思想」を軽く書くと本の格が上がる

### 8.8.5 Server（再定義）

Peer 単体からの変更点

broker 依存が増えたこと

## 8.9 sudo 設定と運用上の割り切り

ExecStopPost + sudo

NOPASSWD の是非

ノード専用ユーザーなら現実的

ここ、かなり実務的で良い章になります。

## 8.10 起動順と動作確認

start / stop の順序

正常系のログの見方

どれが落ちると何が止まるか

## 8.11 Peer + API 構成の運用上の注意

file I/O がボトルネックになる

SSD / NVMe の差が「体感で分かる」

「クソノード」になる条件を正直に書く

👉 ここがこの本の一番の価値ポイント
Peer、Broker間はファイルスプールで受け渡しするため、ファイルIOが増えます。そのため、SSDは必須で、さらにNVMeを推奨します。SSD(sata)でも動きますが、同期遅れが頻発したりプチフォークも発生しやすくなります（つまりハーベスト機会の損失となります）。

<!--
memo:どこかに入れたい
```
Voting ノードをやめる場合、
VotingKey を一度に無効化すると、
有効な Voting Power が急激に減少し、
ネットワーク全体のファイナライズに影響を与える可能性がある。

そのため、実運用では
VotingKey の有効期間を短く設定するなどして、
epoch 単位で段階的に Voting Power を減らしていく方法が現実的である。
```

```
現在の testnet では、比較的大きな Voting Power を
コア開発者側が保持している。
これは、初期段階でネットワークを安定させるために
現実的な選択だったと言える。

一方で、Voting Power が集中している以上、
そのノードが停止した際の影響は大きい。
実際、過去には一部ノードの停止が
ファイナライズに影響した事例もあった。

こうした背景を受け、約半年前に
Voting Power の分布を調整する変更が行われ、
単一ノードの停止では
ファイナライズが止まりにくくなっている。

Voting ノードは、ネットワークの可用性に直接影響する役割を担う。
現状では報酬は設定されていないが、
運用責任の重さを考えると、
何らかのインセンティブ設計があっても不自然ではない。

これは「利益のために Voting を行う」ためではなく、
長期的に安定した運用を促すための仕組みとして検討される余地がある。

```
Voting ノード運用チェックリスト（現実版）
① 資金面（ここがスタート地点）

□ Voting 要件を満たす XYM を保有している
（300万XYM以上、※将来変わる可能性あり）

□ 価格変動で要件を割らない余裕がある

□ Voting 用資金を長期間ロックする覚悟がある

□ 「途中で売りたい」と思っても即やめない判断ができる

👉
お金がある＝適性があるではないけど、
お金が足りない＝即NGなのは事実。

② 時間・継続性（意外と一番重要）

□ 最低でも半年〜1年は続けるつもりがある

□ 鍵の期限（VotingKey）を管理できる

□ 「忙しい時期」でも最低限の確認ができる

□ やめる時も計画的にやめられる

Voting は
「立てたら終わり」じゃなくて
**「期限を忘れたら事故る」役割。

③ 運用耐性（技術＋生活）

□ ノードが落ちた時に気づける監視がある

□ 再起動・復旧を自動化している

□ 深夜・外出時でも最低限の対応ができる

□ OS / ミドルウェア更新を怖がりすぎない

「落ちない」より
**「落ちても戻せる」方が重要。

④ ネットワーク影響の理解（ここが Voting 特有）

□ 自分の Voting Power がどのくらいか把握している

□ 自分が落ちた時、ネットワークに影響が出るか想像できる

□ アンリンク／期限切れが“落ちるのと同じ”と理解している

□ testnet なら試せるが、mainnet では慎重にする意識がある

ここが分かってない人は
Voting をやるべきではない。

⑤ やめ方の設計（ここ超重要）

□ VotingKey を一気に無効化しない計画がある

□ 期限を短くして段階的に減らす選択肢を理解している

□ 「やめる日」を事前に決められる

□ コミュニティへの影響を意識できる

Voting は
始め方より、やめ方の方が難しい。

⑥ 動機の確認（最後に自問する）

□ 「報酬がなくても続けられるか」

□ 「誰かが困るかもしれない」ことを想像できるか

□ 責任を負う役割だと理解しているか

ここで詰まるなら、
Peer や light-api で止めるのも正解。
-->

# 第9章：Voting ノードの運用と判断

## 9.1 Voting ノードとは何か

第8章までで扱ってきた Peer ノードや Peer + API ノードは、
主に「自分のノードが正しく同期し、情報を提供する」ことが役割でした。

Voting ノードは、それとは役割が異なります。

Voting ノードは、
ブロックが最終的に確定（Finalized）するかどうかの判断に参加するノードです。
これは単なる機能追加ではなく、
ネットワーク全体の状態に直接関与する役割を引き受けることを意味します。

Peer や API ノードが停止した場合、その影響は主に自分のノードに留まります。
一方で Voting ノードは、停止や設定ミスが
ネットワーク全体のファイナライズに影響する可能性があります。

この章では、Voting ノードを「どう設定するか」ではなく、
どう向き合い、どう判断するかを中心に扱います。

## 9.2 VotingKey とファイナライズの基本的な考え方

Voting ノードとして動作するためには、VotingKey が必要です。

VotingKey には以下の特徴があります。

有効開始と有効終了が決まっている

有効な期間内のみ、ファイナライズの投票に参加する

有効期限を過ぎると、自動的に無効になる

重要なのは、
VotingKey を持っていること自体が投票権になるわけではないという点です。

Voting ノードとして参加するためには、
一定量以上の XYM を保持していることが条件となっています
（本書執筆時点では 300 万 XYM）。

ただし、この 300 万 XYM はあくまで「参加資格」です。

実際にファイナライズが成立するかどうかは、
有効な Voting Power の合計が全体の 2/3 を超えているかで決まります。

つまり、

300 万 XYM を満たしていても

有効な Voting Power の合計が 2/3 を下回れば

ファイナライズは成立しません。

## 9.3 testnet における Voting ノードの設定方法（実践編）

本節では、testnet 環境で Voting ノードを有効化するための
最低限の設定手順を示す。
mainnet での運用を推奨するものではなく、
Voting の挙動を理解するための検証用途を前提としている。

testnet は本番に影響を与えずに挙動を確認できる環境だが、
Voting ノードに関しては、testnet であっても
十分な XYM を用意する必要がある。

そのため、多くの運用者は
Voting の挙動を実際に試すことなく、
仕様や他者の報告から理解することになる。

前提条件

Peer + API ノードが正常に動作している
（第8章の構成が完了していること）

testnet の XYM を十分に保有している
（Voting 要件を満たしていること）

ノード停止・鍵失効を testnet で試す意思がある

### 9.3.1 testnet 用設定であることの確認

まず、ノードが testnet 向けに設定されていることを確認する。

# resources/config-network.properties

networkIdentifier = testnet

VotingKey は networkIdentifier に依存するため、
mainnet / testnet を取り違えると無効になります。

### 9.3.2 VotingKey の生成（概要）

VotingKey は通常、SDK もしくは独自ツールを用いて生成します。
本書では具体的なコードは扱いませんが、
生成時には以下を指定します。

VotingKey 公開鍵

開始 epoch

終了 epoch

重要なのは、有効期間を短めに設定することです。

例：
開始 epoch : 現在 + 1
終了 epoch : 開始 + 数十 epoch

testnet では、

期限切れ

再生成

再リンク

を試すこと自体が目的になります。

### 9.3.3 VotingKeyLink トランザクションの送信

生成した VotingKey を、
ノードのアカウントにリンクします。

VotingKeyLinkTransaction

Action : Link

この操作を行った時点では、
即座に Voting が始まるわけではありません。

Voting は、
指定した開始 epoch に到達してから有効になります。

### 9.3.4 ノード側の設定（VotingKey の配置）

catapult ノードが VotingKey を参照できるよう、
所定のディレクトリに VotingKey を配置します。

/opt/symbol-node/data/votingkeys

VotingKey ファイル名や配置方法は、
catapult の仕様に従います。

このディレクトリが正しく設定されていない場合、
ノードは Voting に参加しません。

### 9.3.5 ノード再起動とログ確認

VotingKey を配置したら、
ノードを再起動します。

sudo systemctl restart symbol

起動後、ログに以下のような情報が出力されているか確認します。

VotingKey を読み込んだ旨のログ

有効 epoch の情報

Finalization 関連ログ

ログに VotingKey 関連の出力が無い場合、
キー配置や networkIdentifier を再確認してください。

### 9.3.6 ファイナライズ参加の確認

Voting ノードとして正しく動作しているかは、
以下の情報で確認できます。

/finalization/height

/finalization/proof

testnet では、VotingKey の有効化・無効化に伴い、

ファイナライズが継続する

遅延する

停止する

といった挙動を観測できます。

### 9.3.7 testnet で試しておきたい検証項目

testnet では、以下を意図的に試す価値があります。

VotingKey の期限切れ

VotingKey のアンリンク

ノード停止と復帰

epoch 境界での挙動変化

これらの検証を通じて、

Voting は「設定したら終わり」ではなく
常に状態を持つ運用対象である

ことを体感できます。

### 補足：mainnet ではどう違うか

mainnet では、

VotingKey の期限

ノード停止

アンリンク

いずれも 直接ネットワークに影響します。

testnet で十分に挙動を確認し、
「自分が落ちたときに何が起きるか」を理解したうえでのみ、
mainnet での Voting を検討すべきです。

## 9.4 Voting ノードが「落ちる」とはどういうことか

Voting ノードが「落ちる」という状況は、
単にプロセスが停止する場合だけを指すわけではありません。

ファイナライズの観点では、次の 3 つは本質的に同じ扱いになります。

ノードが停止している

VotingKey をアンリンクしている

VotingKey の有効期限が切れている

ネットワークから見れば、
**いずれも「投票しない Voting ノード」**です。

その結果、有効な Voting Power の合計が減少します。
もしその合計が 2/3 を下回れば、
ファイナライズは停止します。

この挙動は、仕様上も自然なものです。
停止したノードの Voting Power が
自動的に他のノードへ再配分されることはありません。

## 9.5 testnet における Voting Power の分布と現実

testnet では、比較的大きな Voting Power を
コア開発者側が保持している状況が続いています。

これは、testnet を安定して運用するための
現実的な選択だったと言えます。

一方で、大きな Voting Power を持つノードが
一時的に停止した場合、その影響は小さくありません。

過去には、特定の Voting ノードの停止が重なり、
ファイナライズに影響が出たこともありました。

こうした状況を受けて、
約半年前に Voting Power の分布を調整する変更が行われ、
現在では単一ノードの停止では
ファイナライズが止まりにくい状態になっています。

ただし、testnet は「絶対に止まらない」ネットワークではありません。
分布次第では、複数の大きな Voting ノードが同時に停止すると
ファイナライズが止まる可能性は残っています。

## 9.6 VotingKey の期限管理が最重要である理由

Voting ノード運用で特に注意すべき点は、
VotingKey の有効期限管理です。

ノード自体が正常に稼働していても、
VotingKey が期限切れになると、そのノードは投票に参加しません。

この状態は一見すると気づきにくく、
ログやファイナライズ状況を確認しない限り、
問題が表面化しないことがあります。

実運用では、
障害よりも期限切れによる影響の方が
深刻になるケースも珍しくありません。

Voting ノードを運用する場合、
期限管理は「付随作業」ではなく、
運用の中核として扱う必要があります。

## 9.7 Voting をやめるという運用

Voting ノードをやめる場合、
注意すべきなのは「一気にやめない」ことです。

VotingKey を突然アンリンクしたり、
期限を一斉に切らしたりすると、
有効な Voting Power が急激に減少します。

その結果、ネットワーク全体のファイナライズに
影響を与える可能性があります。

現実的なやめ方としては、

VotingKey の有効期間を短く設定する

epoch 単位で段階的に Voting Power を減らす

といった方法が考えられます。

Voting をやめるときは、
「抜ける」のではなく
**「少しずつ減らす」**という意識が重要です。

## 9.8 Voting ノード運用チェックリスト

Voting ノードを運用する前に、
次の点を自分自身に問いかける必要があります。

十分な XYM を長期間保持できるか

期限管理を継続できるか

ノード停止に気づき、対応できる体制があるか

自分の Voting Power がネットワークに与える影響を理解しているか

やめるときの計画を立てられるか

これらの問いに一つでも不安がある場合、
Voting ノードを運用しない判断は、十分に正当です。

## 9.9 Voting ノードに報酬は必要か

現在、Voting ノードには
明確な報酬は用意されていません。

しかし、Voting ノードが担う責任の重さを考えると、
何らかのインセンティブ設計があっても不自然ではありません。

報酬は、
単に参加者を増やすためのものではなく、
長期的な安定運用を促すための仕組みとして
議論される余地があります。

一方で、報酬設計を誤ると、
管理が不十分な Voting ノードが増え、
逆に安定性を損なう可能性もあります。

この点については、
今後も慎重な検討が必要でしょう。

## 9.10 まとめ：Voting は覚悟の選択である

Voting ノードの運用は、
技術的な難易度以上に、
責任と継続性が求められます。

すべてのノード運用者が
Voting を行う必要はありません。

Peer ノードや light-api で止める判断も、
ネットワークにとって十分に価値があります。

Voting ノードを運用するということは、
Symbol ネットワークの一部を
自ら引き受けるという選択です。

その覚悟を持てるかどうかが、
この章で最も重要な判断基準になります。

# 終章：Docker を使わない Symbol ノード運用を振り返って

本書では、Docker を使わずに Symbol ノードを構築・運用する方法を扱ってきました。
Peer ノードから始まり、light-api、フル REST、そして Voting ノードまで、
段階的に役割を拡張していく構成を取っています。

この章では、新しい手順や設定は扱いません。
これまでの内容を振り返りながら、
Docker を使わない運用で「分かったこと」「分からなかったこと」、
そして「向き・不向き」について整理します。

## Docker を使わなかった理由

Docker を使わない選択は、
必ずしも思想的なものではありません。

Docker 自体の更新でノードが止まることがある

コンテナの外と中の境界が分かりにくい

障害時に「どこで何が起きているか」を追いにくい

といった、運用上の経験的な理由によるものです。

systemd でプロセスを直接管理し、
FHS に沿ってファイルを配置する構成は、
一見すると古典的ですが、
「何が動いているか」「どこにあるか」を把握しやすいという利点があります。

## 実際に運用して分かったこと

Docker を使わない構成は、
決して楽な構成ではありません。

設定ファイルは自分で管理する必要がある

ミドルウェアの更新は自己責任になる

構成を誤ると、復旧に時間がかかる

一方で、

ノードがどの順序で起動するかが明確になる

ログの所在が分かりやすい

障害時に「想定外」が減る

といったメリットも確かに存在します。

これは「簡単かどうか」ではなく、
**「把握できるかどうか」**の問題だと感じています。

## Docker を使わない運用の限界

この構成は、すべての人に向いているわけではありません。

自動化された環境を好む場合

複数台を一気に展開したい場合

環境差分を極力減らしたい場合

こうした用途では、
Docker を使った構成の方が合理的でしょう。

また、Voting ノードのように
ネットワーク全体に影響を与える役割になると、
技術的な知識だけでなく、
時間や資金、継続性といった現実的な条件も必要になります。

## それでも、この構成を書く意味

本書の構成は、
「最も楽な方法」や「最も一般的な方法」ではありません。

それでもあえて書いたのは、

ノードが何をしているのか

どこで壊れうるのか

落ちたとき、何が止まるのか

を 自分の言葉で説明できる状態を作るためです。

Docker を使うかどうかに関わらず、
この理解は Symbol ノード運用において重要です。

## やらない判断も、正しい

本書をここまで読んで、

Peer ノードだけで十分だと感じた

light-api までで止めたいと思った

Voting は自分には重すぎると判断した

のであれば、その判断は正しいものです。

すべてのノードが Voting を行う必要はありません。
それぞれの役割が分かれていること自体が、
ネットワークの強さにつながります。

## おわりに

Symbol ノードの運用は、
派手さのある作業ではありません。

しかし、静かに動き続けるノードの積み重ねが、
ネットワーク全体を支えています。

本書が、
「ノードを立てること」だけでなく、
**「どう関わるかを考える材料」**として
役に立てば幸いです。

────────────────────
奥付
────────────────────

書名：Docker を使わない Symbol ノード運用
著者：〇〇（ハンドルネーム可）

初版発行：2026年◯月◯日
発行者：〇〇（個人）

本書の内容は執筆時点の情報に基づいています。
本書の情報を用いた運用によって生じたいかなる損害についても、
著者は責任を負いません。

本書に関する情報・修正点は、
以下で公開しています。
https://github.com/xxxxx
