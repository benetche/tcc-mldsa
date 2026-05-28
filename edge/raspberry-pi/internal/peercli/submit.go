// Package peercli submete transações via peer CLI (dois endossos) — robusto com CCAAS no host.
package peercli

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Config para invoke/query peer.
type Config struct {
	FabricSamplesDir string
	Channel          string
	Chaincode        string
	MSPDir           string
	TLSCert          string
	PeerEndpoint     string
}

// SubmitObservation executa RegisterObservation + ReadObservation via peer CLI.
// signAlg e deviceSignature são opcionais (assinatura na borda C1/C2).
func SubmitObservation(cfg Config, obsID, deviceID, payloadHash, recordedAt, signAlg, deviceSignature string) (latencyMs int64, ledgerJSON []byte, err error) {
	tn := filepath.Join(cfg.FabricSamplesDir, "test-network")
	ordererCA := filepath.Join(tn, "organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem")
	peer1TLS := filepath.Join(tn, "organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt")
	peer2TLS := filepath.Join(tn, "organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt")

	host, _, err := net.SplitHostPort(cfg.PeerEndpoint)
	if err != nil {
		host = "localhost"
	}

	var peer1Addr, peer2Addr, ordererAddr string
	switch host {
	case "localhost", "127.0.0.1", "::1":
		peer1Addr = cfg.PeerEndpoint
		peer2Addr = net.JoinHostPort(host, "9051")
		ordererAddr = net.JoinHostPort(host, "7050")
	default:
		// Certificados TLS do test-network usam DNS SAN (peer0.org1.example.com), não IP.
		peer1Addr = "peer0.org1.example.com:7051"
		peer2Addr = "peer0.org2.example.com:9051"
		ordererAddr = "orderer.example.com:7050"
	}

	env := os.Environ()
	env = append(env,
		"CORE_PEER_TLS_ENABLED=true",
		"CORE_PEER_LOCALMSPID=Org1MSP",
		fmt.Sprintf("CORE_PEER_MSPCONFIGPATH=%s", cfg.MSPDir),
		fmt.Sprintf("CORE_PEER_TLS_ROOTCERT_FILE=%s", peer1TLS),
		fmt.Sprintf("CORE_PEER_ADDRESS=%s", peer1Addr),
		fmt.Sprintf("FABRIC_CFG_PATH=%s", filepath.Join(cfg.FabricSamplesDir, "config")),
	)

	invokeBody, err := json.Marshal(map[string]any{
		"function": "RegisterObservation",
		"Args":     []string{obsID, deviceID, payloadHash, recordedAt, signAlg, deviceSignature},
	})
	if err != nil {
		return 0, nil, err
	}
	invokeArgs := string(invokeBody)

	start := time.Now()
	invoke := exec.Command("peer", "chaincode", "invoke",
		"-o", ordererAddr,
		"--ordererTLSHostnameOverride", "orderer.example.com",
		"--tls",
		"--cafile", ordererCA,
		"-C", cfg.Channel,
		"-n", cfg.Chaincode,
		"--peerAddresses", peer1Addr,
		"--tlsRootCertFiles", peer1TLS,
		"--peerAddresses", peer2Addr,
		"--tlsRootCertFiles", peer2TLS,
		"-c", invokeArgs,
	)
	invoke.Env = env
	out, err := invoke.CombinedOutput()
	if err != nil {
		return 0, nil, fmt.Errorf("peer invoke: %w\n%s", err, string(out))
	}
	latencyMs = time.Since(start).Milliseconds()

	time.Sleep(2 * time.Second)

	queryArgs := fmt.Sprintf(`{"function":"ReadObservation","Args":["%s"]}`, obsID)
	query := exec.Command("peer", "chaincode", "query",
		"-C", cfg.Channel,
		"-n", cfg.Chaincode,
		"-c", queryArgs,
	)
	query.Env = env
	qout, err := query.CombinedOutput()
	if err != nil {
		return latencyMs, nil, fmt.Errorf("peer query: %w\n%s", err, string(qout))
	}
	ledgerJSON = []byte(strings.TrimSpace(string(qout)))
	return latencyMs, ledgerJSON, nil
}

// OutputJSON imprime resultado C1/C2 no stdout.
func OutputJSON(obsID string, latencyMs int64, ledgerJSON []byte) error {
	scenario := os.Getenv("IOMT_SCENARIO")
	network := os.Getenv("FABRIC_NETWORK")
	if scenario == "" {
		if network == "mldsa" {
			scenario = "C2"
		} else {
			scenario = "C1"
		}
	}
	if network == "" {
		network = "baseline"
	}
	out := map[string]any{
		"scenario":    scenario,
		"network":     network,
		"client":      "peer-cli",
		"observation": obsID,
		"latency_ms":  latencyMs,
		"ledger":      json.RawMessage(ledgerJSON),
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	return enc.Encode(out)
}
