//go:build gateway

package main

import (
	"crypto/x509"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
	"github.com/hyperledger/fabric-gateway/pkg/hash"
	"github.com/hyperledger/fabric-gateway/pkg/identity"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)

func submitGateway(obsID, deviceID, payloadHash, recordedAt string) error {
	cfg := loadGatewayConfig()
	certPEM, err := readPEMFile(cfg.CertPath)
	if err != nil {
		return fmt.Errorf("cert: %w", err)
	}
	keyPEM, err := os.ReadFile(cfg.KeyPath)
	if err != nil {
		return fmt.Errorf("key: %w", err)
	}
	certificate, err := identity.CertificateFromPEM(certPEM)
	if err != nil {
		return err
	}
	id, err := identity.NewX509Identity(cfg.MSPID, certificate)
	if err != nil {
		return err
	}
	privateKey, err := identity.PrivateKeyFromPEM(keyPEM)
	if err != nil {
		return err
	}
	sign, err := identity.NewPrivateKeySign(privateKey)
	if err != nil {
		return err
	}

	conn, err := newGRPCConnection(cfg.TLSCertPath, cfg.PeerEndpoint, cfg.GatewayPeer)
	if err != nil {
		return err
	}
	defer conn.Close()

	gw, err := client.Connect(
		id,
		client.WithSign(sign),
		client.WithHash(hash.SHA256),
		client.WithClientConnection(conn),
		client.WithEvaluateTimeout(5*time.Second),
		client.WithEndorseTimeout(30*time.Second),
		client.WithSubmitTimeout(10*time.Second),
		client.WithCommitStatusTimeout(2*time.Minute),
	)
	if err != nil {
		return err
	}
	defer gw.Close()

	contract := gw.GetNetwork(cfg.Channel).GetContract(cfg.Chaincode)
	start := time.Now()
	_, err = contract.SubmitTransaction("RegisterObservation", obsID, deviceID, payloadHash, recordedAt)
	latency := time.Since(start)
	if err != nil {
		return err
	}
	result, err := contract.EvaluateTransaction("ReadObservation", obsID)
	if err != nil {
		return err
	}

	out := map[string]any{
		"scenario":    "C1",
		"network":     "baseline",
		"client":      "gateway",
		"observation": obsID,
		"latency_ms":  latency.Milliseconds(),
		"ledger":      json.RawMessage(result),
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	return enc.Encode(out)
}

type gatewayConfig struct {
	MSPID, CertPath, KeyPath, TLSCertPath, PeerEndpoint, GatewayPeer, Channel, Chaincode string
}

func loadGatewayConfig() gatewayConfig {
	peerHost := envOr("FABRIC_GATEWAY_HOST", "peer0.org1.example.com")
	peerAddr := envOr("FABRIC_PEER_ENDPOINT", "localhost:7051")
	return gatewayConfig{
		MSPID:        envOr("FABRIC_MSP_ID", "Org1MSP"),
		CertPath:     envOr("FABRIC_CERT_PATH", ""),
		KeyPath:      envOr("FABRIC_KEY_PATH", ""),
		TLSCertPath:  envOr("FABRIC_TLS_CERT_PATH", ""),
		PeerEndpoint: fmt.Sprintf("dns:///%s", peerAddr),
		GatewayPeer:  peerHost,
		Channel:      envOr("FABRIC_CHANNEL", "iomtchannel"),
		Chaincode:    envOr("FABRIC_CHAINCODE", "iomt"),
	}
}

func newGRPCConnection(tlsCertPath, peerEndpoint, gatewayPeer string) (*grpc.ClientConn, error) {
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
	creds := credentials.NewClientTLSFromCert(pool, gatewayPeer)
	return grpc.NewClient(peerEndpoint, grpc.WithTransportCredentials(creds))
}

func readPEMFile(path string) ([]byte, error) {
	info, err := os.Stat(path)
	if err != nil {
		return nil, err
	}
	if info.IsDir() {
		entries, err := os.ReadDir(path)
		if err != nil {
			return nil, err
		}
		for _, e := range entries {
			if !e.IsDir() {
				return os.ReadFile(filepath.Join(path, e.Name()))
			}
		}
		return nil, fmt.Errorf("nenhum certificado em %s", path)
	}
	return os.ReadFile(path)
}
