// gRPC load test for TempConv2 backend.
// Run: go run . [target] [concurrency] [requests]
// Example: go run . localhost:9090 10 1000
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"sync"
	"sync/atomic"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"tempconv2-backend/gen"
)

func main() {
	target := flag.String("target", "localhost:9090", "Backend gRPC address (host:port)")
	concurrency := flag.Int("c", 10, "Concurrent workers")
	requests := flag.Int("n", 1000, "Total requests")
	flag.Parse()

	conn, err := grpc.NewClient(*target, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer conn.Close()
	client := gen.NewTempConvServiceClient(conn)

	ctx := context.Background()
	var ok, errCount int64
	start := time.Now()
	var wg sync.WaitGroup
	perWorker := *requests / *concurrency

	for w := 0; w < *concurrency; w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := 0; i < perWorker; i++ {
				req := &gen.ConversionRequest{Value: float64(i % 100)}
				_, err := client.CelsiusToFahrenheit(ctx, req)
				if err != nil {
					atomic.AddInt64(&errCount, 1)
				} else {
					atomic.AddInt64(&ok, 1)
				}
			}
		}()
	}
	wg.Wait()
	elapsed := time.Since(start)

	fmt.Printf("Target: %s  Concurrency: %d  Total: %d\n", *target, *concurrency, *requests)
	fmt.Printf("OK: %d  Errors: %d\n", ok, errCount)
	fmt.Printf("Duration: %v  RPS: %.1f\n", elapsed.Round(time.Millisecond), float64(*requests)/elapsed.Seconds())
}
