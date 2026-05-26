// Cliente IoMT no Raspberry Pi — cenário C1 (Fabric baseline / ECDSA).
// Requer connection profile e credenciais Org1 exportadas do test-network.
package main

import (
	"crypto/x509"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
	"github.com/hyperledger/fabric-gateway/pkg/hash"
	"github.com/hyperledger/fabric-gateway/pkg/identity"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	cfg := loadConfig()
	certPEM, err := os.ReadFile(cfg.CertPath)
	if err != nil {
		fatal("cert", err)
	}
	keyPEM, err := os.ReadFile(cfg.KeyPath)
	if err != nil {
		fatal("key", err)
	}
	id, err := identity.NewX509Identity(cfg.MSPID, string(certPEM))
	if err != nil {
		fatal("identity", err)
	}
	key, err := identity.NewPrivateKeyFromPEM(keyPEM)
	if err != nil {
		fatal("private key", err)
	}
	sign, err := identity.NewSigner(key, hash.SHA256)
	if err != nil {
		fatal("signer", err)
	}

	conn, err := newGRPCConnection(cfg.TLSCertPath, cfg.PeerEndpoint)
	if err != nil {
		fatal("grpc", err)
	}
	defer conn.Close()

	gw, err := client.Connect(id, client.WithSign(sign), client.WithHash(hash.SHA256), client.WithClientConnection(conn))
	if err != nil {
		fatal("gateway connect", err)
	}
	defer gw.Close()

	network, err := gw.GetNetwork(cfg.Channel)
	if err != nil {
		fatal("network", err)
	}
	contract := network.GetContract(cfg.Chaincode)

	obsID := fmt.Sprintf("pi-%d", time.Now().UnixNano())
	deviceID := envOr("IOMT_DEVICE_ID", "pi-lab-001")
	payloadHash := envOr("IOMT_PAYLOAD_HASH", "sha256:fixture-pi-smoke")
	recordedAt := time.Now().UTC().Format(time.RFC3339)

	start := time.Now()
	_, err = contract.SubmitTransaction("RegisterObservation", obsID, deviceID, payloadHash, recordedAt)
	latency := time.Since(start)
	if err != nil {
		fatal("submit", err)
	}

	result, err := contract.EvaluateTransaction("ReadObservation", obsID)
	if err != nil {
		fatal("evaluate", err)
	}

	out := map[string]any{
		"scenario":    "C1",
		"network":     "baseline",
		"observation": obsID,
		"latency_ms":  latency.Milliseconds(),
		"ledger":      json.RawMessage(result),
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	_ = enc.Encode(out)
}

type config struct {
	MSPID         string
	CertPath      string
	KeyPath       string
	TLSCertPath   string
	PeerEndpoint  string
	Channel       string
	Chaincode     string
}

func loadConfig() config {
	return config{
		MSPID:        envOr("FABRIC_MSP_ID", "Org1MSP"),
		CertPath:     envOr("FABRIC_CERT_PATH", ""),
		KeyPath:      envOr("FABRIC_KEY_PATH", ""),
		TLSCertPath:  envOr("FABRIC_TLS_CERT_PATH", ""),
		PeerEndpoint: envOr("FABRIC_PEER_ENDPOINT", "localhost:7051"),
		Channel:      envOr("FABRIC_CHANNEL", "iomtchannel"),
		Chaincode:    envOr("FABRIC_CHAINCODE", "iomt"),
	}
}

func newGRPCConnection(tlsCertPath, peerEndpoint string) (*grpc.ClientConn, error) {
	if tlsCertPath == "" {
		return grpc.NewClient(peerEndpoint, grpc.WithTransportCredentials(insecure.NewCredentials()))
	}
	caPEM, err := os.ReadFile(tlsCertPath)
	if err != nil {
		return nil, err
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(caPEM) {
		return nil, fmt.Errorf("falha ao parsear CA TLS")
	}
	creds := credentials.NewClientTLSFromCert(pool, "")
	return grpc.NewClient(peerEndpoint, grpc.WithTransportCredentials(creds))
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func fatal(step string, err error) {
	fmt.Fprintf(os.Stderr, "erro em %s: %v\n", step, err)
	if cfg := loadConfig(); cfg.CertPath == "" {
		fmt.Fprintln(os.Stderr, "Defina FABRIC_CERT_PATH, FABRIC_KEY_PATH, FABRIC_TLS_CERT_PATH (ver edge/raspberry-pi/README.md)")
	}
	os.Exit(1)
}
