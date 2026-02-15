package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"tempconv2-backend/gen"

	"google.golang.org/grpc"
)

type server struct {
	gen.UnimplementedTempConvServiceServer
}

func (s *server) CelsiusToFahrenheit(ctx context.Context, req *gen.ConversionRequest) (*gen.ConversionResponse, error) {
	result := (req.Value * 9 / 5) + 32
	return &gen.ConversionResponse{
		Input:       req.Value,
		Output:      result,
		FromUnit:    "Celsius",
		ToUnit:      "Fahrenheit",
		Description: fmt.Sprintf("%.2f\u00B0C = %.2f\u00B0F", req.Value, result),
	}, nil
}

func (s *server) FahrenheitToCelsius(ctx context.Context, req *gen.ConversionRequest) (*gen.ConversionResponse, error) {
	result := (req.Value - 32) * 5 / 9
	return &gen.ConversionResponse{
		Input:       req.Value,
		Output:      result,
		FromUnit:    "Fahrenheit",
		ToUnit:      "Celsius",
		Description: fmt.Sprintf("%.2f\u00B0F = %.2f\u00B0C", req.Value, result),
	}, nil
}

func runHealthServer(port string) {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"healthy"}`))
	})
	log.Printf("health server listening on :%s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatalf("health server: %v", err)
	}
}

func main() {
	grpcPort := os.Getenv("GRPC_PORT")
	if grpcPort == "" {
		grpcPort = "9090"
	}
	healthPort := os.Getenv("HEALTH_PORT")
	if healthPort == "" {
		healthPort = "9091"
	}

	// Start HTTP health server (for K8s probes)
	go runHealthServer(healthPort)

	lis, err := net.Listen("tcp", ":"+grpcPort)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	gen.RegisterTempConvServiceServer(s, &server{})
	log.Printf("gRPC server listening on :%s", grpcPort)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	go func() {
		if err := s.Serve(lis); err != nil {
			log.Printf("grpc serve: %v", err)
		}
	}()

	<-ctx.Done()
	s.GracefulStop()
}

