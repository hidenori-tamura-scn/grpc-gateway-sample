package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"

	"github.com/golang/glog"
	"github.com/grpc-ecosystem/grpc-gateway/v2/runtime"
	"golang.org/x/net/context"
	"google.golang.org/grpc"

	gw "local.packages/pb"
)

func run() error {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	mux := runtime.NewServeMux()
	opts := []grpc.DialOption{grpc.WithInsecure()}
	endpoint := fmt.Sprintf("localhost:5001")
	if os.Getenv("IS_DOCKER") == "true" {
		endpoint = fmt.Sprintf("greeter-server:5001")
	}
	err := gw.RegisterHelloWorldServiceHandlerFromEndpoint(ctx, mux, endpoint, opts)
	if err != nil {
		return err
	}

	return http.ListenAndServe(":15000", mux)
}

func main() {
	flag.Parse()
	defer glog.Flush()

	if err := run(); err != nil {
		glog.Fatal(err)
	}
}
