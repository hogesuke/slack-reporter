Slack Reporter
==============

指定の期間に投稿されたメッセージをレポートにまとめるツールです。  
[Slack Silencer](https://github.com/dopin/slack-silencer)と併せて使うことで、作業に集中できる環境を構築できます。

## サンプルイメージ
TODO

## 使い方
#### SlackのAPI tokenを作成
[https://api.slack.com/web:title]より作成可能です。

#### tokenを環境変数に設定
```sh
export SLACK_API_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
#### Slackのユーザ名を環境変数に設定（オプション）  
設定するとSlackのダイレクトメッセージでレポートのパスをお知らせします。
```sh
export SLACK_USER=xxxxxxxxxx
```
#### Slack Reporterをgit clone
```sh
git clone git@github.com:hogesuke/slack-reporter.git
```
##### コマンドラインよりプログラムを実行
```sh
# 9:30から18:30のメッセージを対象にする場合
/path/to/reporter.rb 0930 1830
# 現時刻から1時間前までのメッセージを対象にする場合
/path/to/reporter.rb 60
```
crontabに設定することで自動実行も可能です。

```sh
# 18:30にレポート作成
30 18 * * * /path/to/reporter.rb 0930 1830
```

### ライセンス
MIT