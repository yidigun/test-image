package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

type ResponseData struct {
	URL           string `json:"url"`
	Server        Addr   `json:"server"`
	Client        Addr   `json:"client"`
	XForwardedFor string `json:"x-forwarded-for"`
	XRealIP       string `json:"x-real-ip"`
}

type Addr struct {
	Addr string `json:"addr"`
	Port string `json:"port"`
}

func main() {
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}
	listenAddr := ":" + port

	mux := http.NewServeMux()
	mux.HandleFunc("/", handleRequest)

	server := &http.Server{
		Addr:    listenAddr,
		Handler: mux,
		ConnContext: func(ctx context.Context, c net.Conn) context.Context {
			return context.WithValue(ctx, "localAddr", c.LocalAddr().String())
		},
	}

	// start server in a goroutine
	go func() {
		log.Printf("test-image started on 0.0.0.0:%s\n", port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()

	// signal handling
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	sig := <-quit
	log.Printf("Signal received: %v\n", sig)

	// Graceful Shutdown
	log.Println("test-image stopping...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}
	log.Println("test-image stopped")
}

func handleRequest(w http.ResponseWriter, r *http.Request) {

	clientIP, clientPort, _ := net.SplitHostPort(r.RemoteAddr)
	localAddrStr := r.Context().Value("localAddr").(string)
	serverIP, serverPort, _ := net.SplitHostPort(localAddrStr)

	respData := ResponseData{
		URL: r.URL.String(),
		Server: Addr{
			Addr: serverIP,
			Port: serverPort,
		},
		Client: Addr{
			Addr: clientIP,
			Port: clientPort,
		},
		XForwardedFor: r.Header.Get("x-forwarded-for"),
		XRealIP:       r.Header.Get("x-real-ip"),
	}

	jsonBytes, _ := json.Marshal(respData)
	jsonString := string(jsonBytes)

	log.Printf("request: %s", jsonString)

	// Content Negotiation
	acceptHeader := r.Header.Get("Accept")
	if strings.Contains(acceptHeader, "application/json") {
		w.Header().Set("Content-Type", "application/json")
		w.Write(jsonBytes)
	} else {
		w.Header().Set("Content-Type", "text/plain")
		responseTxt := fmt.Sprintf("Client Addr: %s:%s\nServer Addr: %s:%s\nX-Forwarded-For: %s\nX-Real-Ip: %s\n",
			respData.Client.Addr, respData.Client.Port,
			respData.Server.Addr, respData.Server.Port,
			respData.XForwardedFor,
			respData.XRealIP,
		)
		w.Write([]byte(responseTxt))
	}
}
