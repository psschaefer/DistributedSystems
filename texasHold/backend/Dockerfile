FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod ./
COPY hand/ ./hand/
COPY montecarlo/ ./montecarlo/
COPY api/ ./api/
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o server .

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=build /app/server .
EXPOSE 8080
CMD ["./server"]
