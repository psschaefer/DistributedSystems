package main

import (
	"log"
	"net/http"
	"os"
	"texashold-backend/api"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/api/evaluate", api.HandleEvaluate)
	http.HandleFunc("/api/compare", api.HandleCompare)
	http.HandleFunc("/api/win-probability", api.HandleWinProbability)
	http.HandleFunc("/api/win-probability-multi", api.HandleWinProbabilityMulti)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"healthy"}`))
	})
	http.HandleFunc("/readiness", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	log.Printf("texas hold'em API listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
