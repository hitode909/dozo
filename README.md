dozo
====

概要
----

dozoはwgetサーバーです．

使い方
------
dozoはRackアプリケーションです．起動時に，ファイルを置くディレクトリを指定します．
    DOZO_FILES_ROOT=~/Downloads/ thin start

API
---
/にURIをPOSTすると非同期にwgetします．パラメータは以下です．

uri
:  wgetするURI．省略不可．
cookie
:  Cookieを指定できます．省略可．
user_agent
:  UserAgentを指定できます．省略可．
