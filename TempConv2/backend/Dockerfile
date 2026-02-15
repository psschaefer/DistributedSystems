# Build stage
FROM golang:1.22-alpine AS build

WORKDIR /app

COPY go.mod go.sum* ./
COPY gen/ ./gen/
COPY main.go ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o server .

# Production stage
FROM alpine:3.19

WORKDIR /app

COPY --from=build /app/server .

EXPOSE 9090 9091

CMD ["./server"]
