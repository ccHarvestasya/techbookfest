<!-- title: 速習Symbol SDK ESM対応版 -->

# 1. はじめに

本書は Symbol を題材に、ブロックチェーン SDK を使った基本操作を「ESM 前提」でまとめ直した本です。

アカウントの作成、トランザクションの生成と署名、モザイクやネームスペース、マルチシグ、監視、オフライン署名、検証まで、実際の開発や検証で必要になる操作を一通り扱います。

章構成は、一般的な入門資料でよく採られる流れに沿っています。
いわゆる「速習」的に、手を動かしながら理解できることを重視しています。

その一方で、本書では「実行環境」と「モジュール形式」の前提をできるだけはっきりさせます。

多くの Symbol SDK の利用例は、暗黙的に Node.js を前提としており、CommonJS や Node.js 固有の API に依存した形で書かれています。
学習を始める上では合理的な一方で、実行環境を変えた途端に前提が問題になることも少なくありません。

本書では、ESM を前提とした構成で実装しながら、次の2点を意識できるように進めていきます。

- どの処理がプロトコルとして必要なものか
- どの部分が SDK や実行環境に依存しているか

後半および付録では、Node.js という特定の実行環境への依存を見直したときに、設計や実装がどう変わるかにも触れます。

本書は SDK を否定するためのものではありません。
SDK を使いつつも、前提や依存を理解した上で選べる状態を目指します。

本書が、Symbol を扱う際の実装理解を深める助けになり、あわせて実行環境や依存関係を見直すきっかけになれば幸いです。

# 2. 環境構築

この章では、本書のサンプルコードを動かすための最小限の開発環境を用意します。
本書は JavaScript のモジュール形式として ESM（ECMAScript Modules）を前提に進めます。
実行環境は Node.js を例にしますが、できるだけ特定の環境に依存しない構成を意識します。

## 2.1 エディタについて

本書では、コードエディタとして Visual Studio Code（VS Code）を使います。
必須ではありませんが、利用者が多く拡張機能も充実しているため、以降の説明は VS Code 前提で進めます。

インストール方法は [公式サイト](https://code.visualstudio.com/) を参照してください。

## 2.2 Node.js のインストール（Volta を使用）

Node.js のバージョン管理には Volta を使います。
Volta を使うと、プロジェクトごとに Node.js のバージョンを固定でき、環境差によるトラブルを避けやすくなります。

Volta のインストールは [公式手順](https://docs.volta.sh/guide/getting-started) に従って進めます。ここでは次のコマンドを実行してください。

- Unix

  ```bash
  curl https://get.volta.sh | bash
  ```

- Windows

  ```bash
  winget install Volta.Volta
  ```

## 2.3 Node.js のセットアップ

Volta を使って Node.js をインストールします。

```bash
volta install node
```

インストール後、次のコマンドでバージョンを確認します。

```bash
node -v
npm -v
```

本書では、ESM を正式にサポートしている比較的新しい Node.js を前提とします。

## 2.4 プロジェクトディレクトリの作成

作業用のディレクトリを作成し、移動します。

```bash
mkdir quick-symbol-sdk-esm
cd quick-symbol-sdk-esm
```

ディレクトリ名は任意ですが、以降はこの名前で説明します。

## 2.5 npm 初期化

次に、npm でプロジェクトを初期化します。

```bash
npm init -y
```

生成された `package.json` を開き、`type` を `commonjs` から `module` に変更します。

```json:package.json
{
  "type": "module"
}
```

これで、このプロジェクトは ESM 前提で動作します。

## 2.6 TypeScript と tsx のインストール

本書では、サンプルコードを TypeScript で記述します。
また、ビルドを行わずに TypeScript ファイルを直接実行するため、実行ツールとして tsx を使用します。

次のコマンドで必要なパッケージをインストールします。

```bash
npm install --save-dev typescript tsx
```

## 2.7 tsconfig.json の作成

続いて、TypeScript の設定ファイルを作成します。

```bash
npx tsc --init
```

生成された `tsconfig.json` は、最低限次の方針で設定します。

```json:tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

この設定は、特定の実行環境に強く依存しない形で ESM を扱うことを狙っています。

## 2.8 symbol-sdk のインストール

本書では、Node.js への依存がない `@nemnesia/symbol-sdk` を使用します。
ただし、公式の Symbol SDK と交換可能な構成を保つため、npm のエイリアス機能を使って `symbol-sdk` という名前でインストールします。

```bash
npm install symbol-sdk@npm:@nemnesia/symbol-sdk
```

## 2.9 実行確認

環境が正しくできているか、動かして確認します。

`index.ts` を作成し、次の内容を書きます。

```ts:index.ts
console.log('Symbol SDK ESM environment ready');
```

次のコマンドで実行します。

```bash
npx tsx index.ts
```

メッセージが表示されれば、環境構築は完了です。

## 2.10 補足：コード品質ツールについて

ESLint や Prettier などのコード品質ツールは、チーム開発や長期運用では有効です。
ただし、本書の内容を理解する上で必須ではないため、導入方法の詳細については扱いません。
この章では、ESM を前提とした最小構成の開発環境を整えました。

次章からは、この環境を使って Symbol SDK の具体的な操作を見ていきます。

# 3. アカウント

アカウントは、ブロックチェーン上で「誰が署名したか」を示すための基本単位です。これを基にして、資産の管理や権利の行使などが行われます。
Symbol では、アカウントは「秘密鍵」と「公開鍵」のペアとして扱います。

- 秘密鍵：アカウントの所有を証明する最重要情報。絶対に他人に知られないように保管します。
- 公開鍵：秘密鍵から生成され、署名の検証やアカウントの識別に使います。
- アドレス：公開鍵から作られる、人が扱いやすい形式の文字列です。

アカウントがあれば、Symbol ネットワークでトランザクションを送ったり、モザイクを受け取ったりできます。

## 3.1 アカウント作成

### 3.1.1 秘密鍵から生成

ランダムな秘密鍵を生成してアカウントを作ります。
秘密鍵はアカウントの所有を証明する大切な情報で、ここから公開鍵とアドレスが作られます。

```ts:chapter030101.ts
import { PrivateKey } from "symbol-sdk";
import { SymbolFacade } from "symbol-sdk/symbol";

// ランダムな秘密鍵生成
const privateKey = PrivateKey.random();

// 秘密鍵からアカウント生成
const facade = new SymbolFacade("testnet");
const account = facade.createAccount(privateKey);

console.log("privateKey:", account.keyPair.privateKey.toString());
console.log("publicKey :", account.publicKey.toString());
console.log("address   :", account.address.toString());
```

**実行例**

```text
privateKey: A882DF391CAA90BED9070DBF9AB53C2276973E31F06B85F9****************
publicKey : 372B5E1C47C10A8035367D5BF7804176790FBF5BC58F53F159FDA9EDA464965A
address   : TDTXOJZ56VWY4777JF3NQX3BJSYPCVXBUPPVP6Q
```

### 3.1.2 既存の秘密鍵から生成

すでに秘密鍵を安全に保管している場合や、ウォレットからエクスポートした鍵を使う場合は、この方法でアカウントを復元します。

```ts:chapter030102.ts
import { PrivateKey } from "symbol-sdk";
import { SymbolFacade } from "symbol-sdk/symbol";

// 既存の秘密鍵
const privateKey = new PrivateKey(
  "A882DF391CAA90BED9070DBF9AB53C2276973E31F06B85F9****************",
);

// 秘密鍵からアカウント生成
const facade = new SymbolFacade("testnet");
const account = facade.createAccount(privateKey);

console.log("privateKey:", account.keyPair.privateKey.toString());
console.log("publicKey :", account.publicKey.toString());
console.log("address   :", account.address.toString());
```

**実行例**

```text
privateKey: A882DF391CAA90BED9070DBF9AB53C2276973E31F06B85F9****************
publicKey : 372B5E1C47C10A8035367D5BF7804176790FBF5BC58F53F159FDA9EDA464965A
address   : TDTXOJZ56VWY4777JF3NQX3BJSYPCVXBUPPVP6Q
```

### 3.1.3 ニーモニックから生成

もう1つは、ニーモニック（単語の並び）からアカウントを作る方法です。
ニーモニックがあれば対応する秘密鍵を再生成できるため、アカウントを復元できます。
また、1つのニーモニックから複数のアカウントを安全に派生させることもできます。

```ts:chapter030103.ts
import { Bip32 } from "symbol-sdk";
import { SymbolFacade } from "symbol-sdk/symbol";

// ニーモニック生成
const bip32 = new Bip32();
const mnemonic = bip32.random();
console.log("mnemonic:", mnemonic);

// ニーモニックからアカウント生成
const facade = new SymbolFacade("testnet");
const password = "";
const bip32Node = bip32.fromMnemonic(mnemonic, password);

const maxAccounts = 3;
for (let i = 0; i < maxAccounts; i++) {
  const bip32Path = facade.bip32Path(i);
  const childBip32Node = bip32Node.derivePath(bip32Path);
  const keypair = SymbolFacade.bip32NodeToKeyPair(childBip32Node);
  const account = facade.createAccount(keypair.privateKey);
  console.log(`privateKey: ${account.keyPair.privateKey}`);
  console.log(`publicKey : ${account.publicKey}`);
  console.log(`address   : ${account.address}`);
  console.log("===");
}
```

**実行例**

```text
mnemonic: hobby skin abstract comfort mouse bullet banana sunset mass liberty collect stem aisle accuse cloud enough ***** ***** ***** ***** ***** ***** ***** *****
===
privateKey: 5E4CA5A9AE9258AD4C498D50A8D492CA25BCF2A0FD25880E****************
publicKey : 43F7D852263AB7808C9234EEF496E944B5CF19FB91BE6F6881E1CEFDB0D664E9
address   : TCU2H6EQTY6IR5JZAY6PYKFIWIGGY5SZZMUBEGQ
===
privateKey: E6150D2B47B5B1CA7AE80FD093BC351B858C0764498A0590****************
publicKey : 1F3D9AC4169C9E8B6132AF09A344965CEE0EDEC58CEF96B1D407B0F169655379
address   : TAGXSJZEGEOFRR7ZI6Q2IERQEQLPAM25F4OLHOQ
===
privateKey: 93B34EBA41CFBF692D4FCE7B5C89522C1849C6AEB140BF3D****************
publicKey : CCCA6B17906BD0EB3E30C0D046102350EAF689AF443F019380F53576923CAC74
address   : TDWVMPSZNTC76GUBA3CTMUPFIWA5BCBJN6FS3WQ
```

### 3.2 公開アカウント

公開鍵しか分からなくても、その公開鍵からアカウント情報（公開アカウント）を作れます。
相手のアカウントを参照したいときや、受信専用の情報として扱いたいときに便利です。

```ts:chapter030200.ts
import { PublicKey } from "symbol-sdk";
import { SymbolFacade } from "symbol-sdk/symbol";

// 公開鍵
const publicKey = new PublicKey(
  "43F7D852263AB7808C9234EEF496E944B5CF19FB91BE6F6881E1CEFDB0D664E9",
);

// 公開鍵から公開アカウント生成
const facade = new SymbolFacade("testnet");
const account = facade.createPublicAccount(publicKey);

console.log("publicKey :", account.publicKey.toString());
console.log("address   :", account.address.toString());
```

**実行例**

```text
publicKey : 43F7D852263AB7808C9234EEF496E944B5CF19FB91BE6F6881E1CEFDB0D664E9
address   : TCU2H6EQTY6IR5JZAY6PYKFIWIGGY5SZZMUBEGQ
```

## 3.3 アドレス

公開鍵や秘密鍵が手元になくても、アドレスさえ分かっていればアカウント情報を扱えます。
ただし、秘密鍵がないため署名はできません。また、公開鍵がないためメッセージの暗号化もできません。

```ts
import { SymbolFacade } from "symbol-sdk/symbol";

const address = new SymbolFacade.Address(
  "TCU2H6EQTY6IR5JZAY6PYKFIWIGGY5SZZMUBEGQ",
);

console.log("address   :", address.toString());
```

**実行例**

```text
address   : TCU2H6EQTY6IR5JZAY6PYKFIWIGGY5SZZMUBEGQ
```

---

以降の章では、すでにアカウント（秘密鍵・公開鍵・アドレス）が用意されているものとして説明を進めます。

## 補足資料 1. 日本語ニーモニック

`Bip32` クラスのコンストラクタに `japanese` を指定すると、日本語のニーモニックを生成できます。
ただし、既存のデスクトップウォレットなどでは使えない場合があるため、通常は `english` をおすすめします。

```ts
import { Bip32 } from "symbol-sdk";

// 日本語ニーモニック生成
const bip32 = new Bip32("ed25519", "japanese");
const mnemonic = bip32.random();

console.log("mnemonic:", mnemonic);
```

**実行例**

```text
mnemonic: にってい　ぎろん　だんわ　ねんぶつ　めぐまれる　ぶんぽう　とける　ろじうら　ほそく　おどろかす　くどく　きんようび　＊＊＊　＊＊＊　＊＊＊　＊＊＊　＊＊＊　＊＊＊　＊＊＊　＊＊＊　＊＊＊　＊＊＊　＊＊＊　＊＊＊
```

## 補足資料 2. ニーモニックのパスワード

ニーモニックから秘密鍵を生成するときは、パスワードを指定できます。
パスワードを付けると、ニーモニックだけでは秘密鍵を復元できなくなり、セキュリティが上がります。任意の文字列を使えますが、忘れないように注意してください。

# 4. トランザクション

## 4.1 トランザクションとは

### 4.1.1 トランザクションの基本概念

ブロックチェーンにおける「トランザクション」とは、ネットワークに記録される操作や処理の単位を指します。
銀行における「振込」や「引き落とし」が処理の単位であるのと同様に、ブロックチェーン上では「アカウントからアカウントへの送金」や 「モザイクの発行」といった操作がトランザクションです。

トランザクションは、署名された後にネットワークへアナウンスされ、ノードに伝播し、最終的にブロックに取り込まれることで台帳に記録されます。
これにより、誰でも検証可能な形で「いつ」「誰が」「何をしたか」が保証されます。

### 4.1.2 Symbol ブロックチェーンにおける役割

Symbol ブロックチェーンでは、すべての状態変化はトランザクションによって実現されます。

- アカウント間の XYM 送金
- 新しいモザイク（トークン）の発行
- ネームスペースの登録
- マルチシグアカウントの設定
- アグリゲートトランザクションによる複数操作の一括実行

これらはすべて「トランザクション」という形式で表現され、ブロックチェーンに取り込まれることで有効になります。
つまり、トランザクションは **ブロックチェーンを動かす最小単位の命令** だと捉えることができます。

### 4.1.3 トランザクションの種類（概要）

Symbol では多様な用途に対応するために、複数の種類のトランザクションが用意されています。代表的なものを以下に挙げます。

- **転送トランザクション**
  アカウント間で XYM やモザイクを送信するトランザクション。メッセージも付与可能。

- **アグリゲートトランザクション**
  複数のトランザクションを一つにまとめて実行する仕組み。複数署名者による共同署名も可能。

- **モザイク関連トランザクション**
  新規モザイクの作成、供給量の変更、制約（譲渡制限など）の設定を行う。

- **ネームスペース関連トランザクション**
  ネームスペースの登録や更新を行う。モザイクやアカウントにフレンドリーな名前を付与できる。

- **アカウント関連トランザクション**
  マルチシグ設定、キーリンク、アカウント設定変更など。

これらのトランザクションが組み合わさることで、Symbol ブロックチェーン上で多様なアプリケーションを構築することができます。

## 4.2 トランザクションのライフサイクル

トランザクションは作成されてからブロックに記録されるまで、いくつかの段階を経ます。
この流れを理解しておくことは、アプリケーション開発において「いつ送金が完了したとみなせるか」 「どのタイミングでエラー処理を行うか」を判断する上で重要です。

### 4.2.1 ライフサイクルの流れ

1. 作成
   アプリケーションやウォレットで、送金や操作の内容を指定してトランザクションを生成します。
   例: 送信先アドレス、送信量、手数料、メッセージなどを組み込む。

2. 署名
   作成したトランザクションを秘密鍵で署名します。これにより、
   - 送信者本人が承認したこと
   - 改ざんされていないこと

   が保証されます。

3. アナウンス
   署名済みトランザクションをノードに送信します。SDK を使えば REST API 経由で簡単に行えます。

4. ネットワーク伝播
   受け取ったノードは、P2P ネットワークを通じて他のノードへトランザクションを転送します。
   この段階ではまだブロックに取り込まれていないため「未承認」状態です。

5. ブロック取り込み
   ノードの収集したトランザクションがバリデーションを通過すると、次に生成されるブロックに格納されます。
   ブロックに含まれると「承認済み」となり、さらに最終化が進むことで「確定」します。

### 4.2.2 トランザクションのステータス

トランザクションには以下のステータスがあります。

- **Unconfirmed（未承認）**
  アナウンスされ、ネットワークに伝播しているが、まだブロックに含まれていない状態。

- **Confirmed（承認済み）**
  ブロックに含まれ、チェーンに記録された状態。通常はここで「処理が完了」とみなします。

- **Finalized（確定）**
  ファイナリティが到達し、チェーン分岐の影響を受けない状態。高額取引や重要な処理ではこの状態を待つことがあります。

### 4.2.3 ノード間での伝播の仕組み

Symbol のネットワークは P2P 方式で構築されています。

1. クライアントがトランザクションをノード A にアナウンスする。
1. ノード A は署名や手数料、アカウント残高などを検証する。
1. 問題がなければ、ノード A はトランザクションを保持し、他のピアノードへ転送する。
1. ネットワーク全体にトランザクションが行き渡り、次のブロックで承認される。
1. この仕組みにより、トランザクションは分散的かつ効率的に処理されます。

## 4.3 トランザクション生成の前提知識

### 4.3.1 SDK初期化

```ts
// Symbolファサード生成
const facade = new SymbolFacade("testnet");
```

SymbolFacade は、ネットワーク種別やエポック時間など、トランザクション生成に必要な前提情報をまとめて保持するための中心的なオブジェクトです。

### 4.3.2 送受信者を復元

送信者は署名を行うため、秘密鍵からアカウント情報を復元します。一方、受信者は署名を行わないため、公開鍵またはアドレスが分かれば問題ありません。

```ts
// Aliceアカウント(送信者)
const alicePrivateKey = new PrivateKey(
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
);
const aliceAccount = facade.createAccount(alicePrivateKey);
// Bobアカウント(受信者)
const bobPublicKey = new PublicKey(
  "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
);
const bobPublicAccount = facade.createPublicAccount(bobPublicKey);
```

## 4.4 転送トランザクション

転送トランザクションは最も基本的なトランザクションです。XYM やモザイクを他のアカウントに送金するときに使用します。

### 4.4.1 モザイクの指定

```ts
// 転送モザイク設定(ネームスペースからモザイクIDを解決)
const mosaicId = generateMosaicAliasId("symbol.xym");
const mosaics = [
  new descriptors.UnresolvedMosaicDescriptor(
    new models.UnresolvedMosaicId(mosaicId),
    new models.Amount(10_000000n), // 10 XYM
  ),
];
```

基底通貨であるXYMは分割量 6 なので、1 XYM = 1,000,000 となります。

### 4.4.2 メッセージ

```ts
// 平文メッセージ
const message = new TextEncoder().encode("\0Hello, Symbol!!");

// メッセージエンコード(受信者の公開鍵で暗号化)
// const encodedMessage = await aliceAccount
//   .messageEncoder()
//   .encode(bobPublicAccount.publicKey, message);
```

先頭の `\0` は、平文メッセージであることを示す区別子です。暗号化する場合は、`messageEncoder` が自動的に `\01` を追加します。

※ 上記の暗号化メッセージ生成コードを使用する場合は、転送トランザクション作成時に `message` の代わりに`encodedMessage` を指定する必要があります。

### 4.4.3 手数料と期限

Symbol のトランザクションでは、手数料と有効期限を明示的に指定します。

- 手数料は、トランザクションサイズに手数料係数を掛けて計算されます。
- 有効期限は、作成時点からの相対時間（秒）で指定します。

これにより、過剰な手数料の支払いや、長期間ネットワークに残り続けるトランザクションを防ぎます。

なお、手数料は低く設定できますが、アナウンス先ノードが設定する最低手数料係数に満たない場合、トランザクションは拒否されるので注意が必要です。これは、ノードごとに受け付ける最低手数料が異なるためです。

### 4.4.4 転送トランザクションの作成

これまでに準備した情報を用いて、転送トランザクションを作成します。

```ts
// 転送トランザクションディスクリプタ生成
const transferTxDescriptor = new descriptors.TransferTransactionV1Descriptor(
  bobPublicAccount.address, // 受信者アドレス
  mosaics, // 転送モザイク
  message, // メッセージ
);
// 転送トランザクション生成
const transferTx = facade.createTransactionFromTypedDescriptor(
  transferTxDescriptor,
  aliceAccount.publicKey, // 署名者公開鍵
  100, // 手数料係数
  60 * 60 * 2, // 有効期限(秒)
) as models.TransferTransactionV1;
```

`createTransactionFromTypedDescriptor` の戻り値の型が汎用トランザクション型 `models.Transaction` なので、転送トランザクション型にキャストします。この後のコードで転送トランザクション特有の項目の読み書きをしないなら、キャストせずそのままでも構いません。

このように、転送トランザクションは必要な情報を指定することで、 比較的シンプルなコードで作成できます。

次は、このトランザクションに署名し、ネットワークへアナウンスしてみましょう。

## 4.5 署名とアナウンス

作成したトランザクションは、まだネットワークで有効ではありません。有効化するには次の 2 つのステップが必要です。

### 4.5.1 署名

署名は、送信者本人がトランザクションを承認したことを証明する重要な処理です。

秘密鍵を使用して署名することで

- 送信者本人による承認を証明
- トランザクションの改ざんを防止
- 誰でも送信者と内容を検証可能

となります。

```ts
// アリス署名
const sig = aliceAccount.signTransaction(transferTx);
const payloadJsonString = SymbolTransactionFactory.attachSignature(
  transferTx,
  sig,
);
const txHash = facade.hashTransaction(transferTx);
console.log(`Transaction Hash: ${txHash}`);
```

`signTransaction` は、トランザクションに対する署名データを生成します。 `attachSignature` は、その署名をトランザクションに結合し、ネットワークへ送信可能なペイロード（JSON文字列） を生成します。

この時点で、トランザクションは「誰が・どの内容を・いつ承認したか」が暗号学的に固定された状態になります。

署名が完了し、アナウンス可能な状態になったことで、このタイミングからトランザクションハッシュを算出できるようになります。

次は、この署名済みトランザクションをネットワークへアナウンスします。

### 4.5.2 アナウンス

署名済みトランザクションを、ノードへアナウンスします。

トランザクションのアナウンスは、HTTP リクエストとしてノードに送信するだけの、比較的シンプルな処理です。

```ts
// ノードへトランザクションをアナウンス
const response = await fetch(
  new URL("/transactions", "https://t.sakia.harvestasya.com:3001"),
  {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: payloadJsonString,
  },
);
const result = await response.json();
console.log("announce result:", result);
```

`fetch` の戻り値は、トランザクションの PUT リクエストがノードに正常に受理されたかどうか
を示すものです。

ここで注意すべき点として、

- PUT が成功した
  → ノードがトランザクションを受け取った

- トランザクションが承認・確定した
  → まだ分からない

という違いがあります。

トランザクションがエラーではじかれた場合のエラーメッセージを見るには、WebSocket を用いてリアルタイムで監視する必要があります。WebSocket によるトランザクションの監視方法については、後の章で詳しく解説します。

## 4.6 トランザクションの状態を確認

REST にアクセスすることで、トランザクションがノードに受理されているか、あるいはエラーとして扱われているかを確認できます。

ここでは代表的なエンドポイントのみを示します。
REST の具体的な使い方については、ここでは詳しく説明しません。

### 未承認（Unconfirmed）

```text
https://t.sakia.harvestasya.com:3001/transactions/unconfirmed/{transactionHash}
```

ノードに受理されたものの、まだブロックに取り込まれていない
トランザクションを確認できます。

### 承認済み（Confirmed）

```text
https://t.sakia.harvestasya.com:3001/transactions/confirmed/{transactionHash}
```

ブロックに取り込まれ、承認されたトランザクションを確認できます。

本章では、単一の署名者によるトランザクションを扱いました。
Symbol では、複数の署名者による合意を表現するために、アグリゲートトランザクションという仕組みが用意されています。

アグリゲートトランザクションについては、次章で詳しく解説します。

<!-- ## 付録 -->

<!-- TODO: メッセージの暗号化がv3とv2で異なる。v2向けの暗号化を作るコードをここに書く -->
<!-- TODO: メッセージの複合方法もここに書く -->

# 5. アグリゲートトランザクション

Symbol には、複数のトランザクションを 1 つのトランザクションとしてまとめて扱う仕組みがあります。1 つのアグリゲートトランザクションには、最大 100 件のトランザクションを内包することができます。なお、内包されたトランザクションは配列の順番で検証・適用されます。

## 5.1 アグリゲートコンプリートの基本

アグリゲートコンプリートは、必要な署名がすべて揃った状態（コンプリート）で複数のトランザクションをまとめて発行するときに使用します。

もちろん、内包するトランザクションは転送に限りません。

他にも、メッセージエリアの最大が 1024 バイトのため、1024 バイトより大きな情報を格納したい場合、複数の転送トランザクションをまとめて 1 つのデータとする方法もあります。ただし、過去の世代で用いられていた「分割データ保存」に近い方式となるため、読み出し効率やノードへの容量負荷の観点からおすすめしません。

例えば、Alice から Bob と Carol へ資産の送信を一括で行うケースを考えてみましょう。

### 5.1.1 送受信者を復元

新しく送信相手に Carol を追加します。

```ts
// Aliceアカウント(送信者)
const alicePrivateKey = new PrivateKey(
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
);
const aliceAccount = facade.createAccount(alicePrivateKey);
// Bobアカウント(受信者)
const bobPublicKey = new PublicKey(
  "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
);
const bobPublicAccount = facade.createPublicAccount(bobPublicKey);
const carolPublicKey = new PublicKey(
  "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
);
const carolPublicAccount = facade.createPublicAccount(carolPublicKey);
```

### 5.1.2 メッセージ

```ts
// 平文メッセージ
const message1 = new TextEncoder().encode("\0Hello, Bob!!");
const message2 = new TextEncoder().encode("\0Hello, Carol!!");
```

### 5.1.3 内包する転送トランザクション作成

アグリゲートトランザクション側で指定するので、内部トランザクションには手数料や期限は設定しません。

`mosaics` の定義は、第 4 章を参照してください。

```ts
// 内部トランザクション1（Alice→Bob）
const innerDescriptor1 = new descriptors.TransferTransactionV1Descriptor(
  bobPublicAccount.address, // 受信者アドレス
  mosaics, // 転送モザイク
  message1, // メッセージ
);
const innerTx1 = facade.createEmbeddedTransactionFromTypedDescriptor(
  innerDescriptor1,
  aliceAccount.publicKey, // 署名者公開鍵
);
// 内部トランザクション2（Alice→Carol）
const innerDescriptor2 = new descriptors.TransferTransactionV1Descriptor(
  carolPublicAccount.address, // 受信者アドレス
  mosaics, // 転送モザイク
  message2, // メッセージ
);
const innerTx2 = facade.createEmbeddedTransactionFromTypedDescriptor(
  innerDescriptor2,
  aliceAccount.publicKey, // 署名者公開鍵
);

// 内部トランザクションを配列にまとめる
const innerTxs = [innerTx1, innerTx2];
```

作成した内部トランザクションは配列にして 1 つにまとめます。

### 5.1.4 アグリゲートトランザクション

```ts
// アグリゲートコンプリートトランザクションディスクリプタ生成
const descriptor = new descriptors.AggregateCompleteTransactionV3Descriptor(
  facade.static.hashEmbeddedTransactions(innerTxs), // 内部トランザクションハッシュ
  innerTxs, // 内部トランザクション配列
);
// アグリゲートコンプリートトランザクション生成
const aggregateTx = facade.createTransactionFromTypedDescriptor(
  descriptor,
  aliceAccount.publicKey, // 署名者公開鍵
  100, // 手数料係数
  60 * 60 * 2, // 有効期限(秒)
  0, // 連署者数
);
```

署名は Alice のみ必要でアナウンスするときに署名するので、連署者数は `0` です。

## 5.1.5 署名とアナウンス

あとは第 4 章と同じように Alice で署名しアナウンスします。

```ts
// アリス署名
const sig = aliceAccount.signTransaction(aggregateTx);
const payloadJsonString = SymbolTransactionFactory.attachSignature(
  aggregateTx,
  sig,
);
const txHash = facade.hashTransaction(aggregateTx);
console.log(`Transaction Hash: ${txHash}`);

// ノードへトランザクションをアナウンス
const response = await fetch(
  new URL("/transactions", "https://t.sakia.harvestasya.com:3001"),
  {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: payloadJsonString,
  },
);
const result = await response.json();
console.log("announce result:", result);
```

アグリゲートには、Complete のほかに Bonded という形式もあります。Bonded は署名が揃う前にネットワークへ預けるため、担保として HashLock を必要とします。

Bonded と HashLock については、別章で扱います。

# 6. モザイク

Symbolでは、ブロックチェーン上で扱う資産や数量単位を「モザイク」と呼びます。

XYM もモザイクの一種であり、Symbol においては「トークン」という呼び方で特定の資産を特別視する設計は採られていません。
ネットワークにとっては、XYM もユーザーが定義したモザイクも、同じ形式のデータとして扱われます。

モザイクは、「発行者が定義した識別子付きの数量」を表すための最小単位です。

## 6.1 モザイクの定義

モザイクの定義は、以下の 2 つのトランザクションによって行われます。

- モザイク定義トランザクション
- モザイク供給量変更トランザクション

これらは意味的に不可分なため、本書ではアグリゲートトランザクションとしてまとめて発行します。

### 6.1.2 モザイクフラグ

モザイクフラグは、「あとから何ができて、何ができなくなるか」をあらかじめ固定するための設定です。
一度無効にした操作は、後から有効に戻すことはできません。

以下が設定できます。

- 供給量変更可否
- 譲渡可否
- 制限設定可否
- 還収可否

```ts
// モザイクフラグ設定
let f = models.MosaicFlags.NONE.value;
f += models.MosaicFlags.SUPPLY_MUTABLE.value; // 供給量変更の可否
f += models.MosaicFlags.TRANSFERABLE.value; // 第三者への譲渡可否
f += models.MosaicFlags.RESTRICTABLE.value; // 制限設定の可否
f += models.MosaicFlags.REVOKABLE.value; // 発行者からの還収可否
const mosaicFlags = new models.MosaicFlags(f);
```

### 6.1.3 モザイクナンス

モザイクナンスは、発行者アドレスと組み合わせてモザイクIDを生成するためのランダム値です。
これにより、同じ発行者が複数のモザイクを安全に作成できます。

ここでは、依存を押さえるため `@noble/hashes` を使用しています。

```ts
// ナンス設定
const nonceBytes = randomBytes(models.MosaicNonce.SIZE);
const mosaicNonce = models.MosaicNonce.deserialize(nonceBytes);
```

### 6.1.4 モザイク定義Tx

モザイク定義トランザクションは、モザイクの基本的な性質を決定するためのトランザクションです。
ここで定義された内容は、後から変更できないか、もしくは制限付きでしか変更できないため、設計上の判断が最も重要になります。

`duration`（有効期限）は、ブロック数で指定します。`0` を指定すると無期限となり、期限切れによって自動的に失効することはありません。

`divisibility`（可分性）は、モザイクをどこまで分割できるかを表します。例えば `3` に設定すると、最小単位は `0.001` になります。

```ts
//モザイク定義
const mosaicDefDescriptor =
  new descriptors.MosaicDefinitionTransactionV1Descriptor( // Txタイプ:モザイク定義Tx
    new models.MosaicId(
      generateMosaicId(aliceAccount.address, mosaicNonce.value as number),
    ), // モザイクID
    new models.BlockDuration(0n), // duration:有効期限
    mosaicNonce, // モザイクナンス
    mosaicFlags, // モザイクフラグ
    3, // divisibility:可分性
  );
const mosaicDefTx = facade.createEmbeddedTransactionFromTypedDescriptor(
  mosaicDefDescriptor, // トランザクション Descriptor 設定
  aliceAccount.publicKey, // 署名者公開鍵
) as models.EmbeddedMosaicDefinitionTransactionV1;
```

### 6.1.5 モザイク変更Tx

モザイク供給量変更トランザクションは、既に定義されたモザイクの数量を変更するためのトランザクションです。

数量に `10000`、アクションに `INCREASE` を指定しているため、供給量は `+10000` 増加します。可分性が `3` の場合、実効値としては `+10.000` となります。

供給量を後から変更できるかどうかは、モザイク定義時に設定したフラグ（SUPPLY_MUTABLE）によって決まります。

供給量変更トランザクションは、モザイクの供給量の初期値を設定する目的でも使用されます。
モザイク定義と同時に供給量を確定させるため、2つのトランザクションをアグリゲートでまとめて発行します。

```ts
//モザイク変更
const mosaicChangeDescriptor =
  new descriptors.MosaicSupplyChangeTransactionV1Descriptor( // Txタイプ:モザイク変更Tx
    new models.UnresolvedMosaicId(mosaicDefTx.id.value as bigint), // モザイクID
    new models.Amount(10000n), // 数量
    models.MosaicSupplyChangeAction.INCREASE, // アクション
  );
const mosaicChangeTx = facade.createEmbeddedTransactionFromTypedDescriptor(
  mosaicChangeDescriptor, // トランザクション Descriptor 設定
  aliceAccount.publicKey, // 署名者公開鍵
) as models.EmbeddedMosaicSupplyChangeTransactionV1;
```

### 6.1.6 アグリゲートコンプリートトランザクションでまとめる

```ts
// 内部トランザクションを配列にまとめる
const innerTxs = [mosaicDefTx, mosaicChangeTx];

// アグリゲートコンプリートトランザクションディスクリプタ生成
const descriptor = new descriptors.AggregateCompleteTransactionV3Descriptor(
  facade.static.hashEmbeddedTransactions(innerTxs), // 内部トランザクションハッシュ
  innerTxs, // 内部トランザクション配列
);
// アグリゲートコンプリートトランザクション生成
const aggregateTx = facade.createTransactionFromTypedDescriptor(
  descriptor,
  aliceAccount.publicKey, // 署名者公開鍵
  100, // 手数料係数
  60 * 60 * 2, // 有効期限(秒)
  0, // 連署者数
);
```

## 6.2 モザイクIDを指定した送信

モザイクの送信は、基本的には第 4 章で扱った転送トランザクションと同じ仕組みで行います。
ここでは、ネームスペースを使用せず、モザイクIDを直接指定して送信する方法を示します。
`72C0212E67A08BCE` は、テストネットにおける `symbol.xym` のモザイクIDです。ネットワーク種別によってモザイクIDは異なるため、使用する際は注意してください。

```ts
// モザイクIDを直接指定
const mosaics = [
  new descriptors.UnresolvedMosaicDescriptor(
    new models.UnresolvedMosaicId(0x72c0212e67a08bcen),
    new models.Amount(10_000000n), // 10 XYM
  ),
];
```

ネームスペースは利便性のための仕組みであり、モザイクの本質ではありません。
用途やライフサイクルによっては、あえてネームスペースを割り当てず、モザイクIDを直接扱う方が自然な場合もあります。

## 補足: モザイクIDとネームスペースID

モザイクIDとネームスペースIDは、どちらも 64bit の数値ですが、上位 1bit によって種類が区別されています。

- モザイクID：上位ビットが `0`
- ネームスペースID：上位ビットが `1`

この仕組みにより、ネットワークは追加のメタ情報を持たずに、ID の種類を数値だけで判別できます。
これは、ネームスペースがモザイクとは異なる役割を持つことをプロトコルレベルで明確にするための設計です。

# 7. ネームスペース

## 7.1 手数料の計算

## 7.2 レンタル

## 7.3 リンク

## 7.4 未解決で使用

## 7.5 参照

# 8. メタデータ

SDK使ってキー生成した場合は、上位ビットが1になります。なので、上位ビットが0の範囲を使えばSDKの生成するキーとの衝突を回避できます。

## 8.1 アカウントに登録

## 8.2 モザイクに登録

## 8.3 ネームスペースに登録

## 8.4 確認

# 9. ロック

## 9.1 ハッシュロック

## 9.2 シークレットロック・シークレットプルーフ

# 10. マルチシグ

## 10.1 アカウントの準備

## 10.2 マルチシグの登録

## 10.3 確認

## 10.4 マルチシグ署名

## 10.5 マルチシグ送信の確認

## 10.6 マルチシグ構成変更

# 11. 監視

## 11.1 リスナー設定

## 11.2 受信検知

## 11.3 ブロック監視

## 11.4 署名要求

# 12. 制限

## 12.1 アカウント制限

## 12.2 グローバルモザイク制限

# 13. オフライン署名

## 13.1 トランザクション作成

## 13.2 Bob による連署

## 13.3 Alice によるアナウンス

# 14. 検証

## 14.1 トランザクションの検証

## 14.2 連署の検証

## 14.3 ブロックヘッダーの検証

## 14.4 アカウント・メタデータの検証

# 付録. Symbol SDK の Node.js 依存を抜く
