FROM golang:latest

COPY main.go go.mod C:/app/
WORKDIR C:/app/
RUN go build -a -ldflags "-s" -o test-image.exe
