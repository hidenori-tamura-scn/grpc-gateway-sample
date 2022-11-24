## はじめに

下記サイトを参考にしています。

https://qiita.com/ryu3/items/b2882d4f45c7f8485030

## 注意
下記が必要です。
```
$ go env -w GO111MODULE=off # Go Modules の OFF

$ go get -u -v github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
$ go get -u -v github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
$ go get -u -v github.com/golang/protobuf/protoc-gen-go

$ go env -w GO111MODULE=on # Go Modules の ON（復旧）

$ go mod tidy
```

## 使い方
参考にしたサイトと一緒です。(ポート番号だけ元サイトから変更しています)

下記を別々のターミナルで実行します。

```
$ go run greeter_gateway/main.go #gatewayの起動
```
```
$ go run greeter_server/main.go #serverの起動
```
```
$ curl -X GET http://localhost:15000/v1/example/sayhello/nakata

{"message":"Hello nakata"}

$ curl -X GET http://localhost:15000/v1/example/users/10

{"id":"10","name":"SampleUser"}

$ curl -X POST http://localhost:15000/v1/example/users -d '{"name":"nakata"}'

{"id":"123","name":"nakata"}

```


## その他
proto/service.proto を変更した場合のprotocコマンドは下記の通りです。

```
$ protoc -I/usr/local/include -I. \
  -I$GOPATH/src \
  -I$GOPATH/src/github.com/googleapis/googleapis \
  --go_out=plugins=grpc:. \
  proto/service.proto # gRPC stub側
```
```
$ protoc -I/usr/local/include -I. \
  -I$GOPATH/src \
  -I$GOPATH/src/github.com/googleapis/googleapis \
  --grpc-gateway_out=logtostderr=true:. \
  proto/service.proto # reverse-proxy側
```

