// Cliente IoMT — cenário C1 (Fabric baseline).
// Padrão: peer-cli (dois endossos, compatível com CCAAS). Gateway: IOMT_SUBMIT_MODE=gateway + -tags gateway.
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/beneti/tcc-projeto-mldsa/edge/raspberry-pi/internal/edgesign"
	"github.com/beneti/tcc-projeto-mldsa/edge/raspberry-pi/internal/peercli"
)

func main() {
	obsID := fmt.Sprintf("pi-%d", time.Now().UnixNano())
	deviceID := envOr("IOMT_DEVICE_ID", "pi-lab-001")
	payloadHash := envOr("IOMT_PAYLOAD_HASH", "sha256:fixture-pi-smoke")
	recordedAt := time.Now().UTC().Format(time.RFC3339)

	mode := envOr("IOMT_SUBMIT_MODE", "peer-cli")
	if mode == "gateway" {
		if err := submitGateway(obsID, deviceID, payloadHash, recordedAt); err == nil {
			return
		} else {
			fmt.Fprintf(os.Stderr, "gateway falhou (%v); usando peer-cli\n", err)
		}
	}

	if err := submitPeerCLI(obsID, deviceID, payloadHash, recordedAt); err != nil {
		fmt.Fprintf(os.Stderr, "erro: %v\n", err)
		os.Exit(1)
	}
}

// submitGateway implementado em gateway.go com build tag "gateway".
func submitGateway(_, _, _, _ string) error {
	return fmt.Errorf("recompile com -tags gateway para modo gateway")
}

func submitPeerCLI(obsID, deviceID, payloadHash, recordedAt string) error {
	repoRoot := envOr("REPO_ROOT", "")
	if repoRoot == "" {
		var err error
		repoRoot, err = filepath.Abs(filepath.Join("..", ".."))
		if err != nil {
			return err
		}
	}
	samples := envOr("FABRIC_SAMPLES_DIR", filepath.Join(repoRoot, "fabric-samples"))
	msp := envOr("FABRIC_MSP_DIR", filepath.Join(samples, "test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp"))

	cfg := peercli.Config{
		FabricSamplesDir: samples,
		Channel:          envOr("FABRIC_CHANNEL", "iomtchannel"),
		Chaincode:        envOr("FABRIC_CHAINCODE", "iomt"),
		MSPDir:           msp,
		PeerEndpoint:     envOr("FABRIC_PEER_ENDPOINT", "localhost:7051"),
	}

	path := filepath.Join(samples, "bin")
	_ = os.Setenv("PATH", path+string(os.PathListSeparator)+os.Getenv("PATH"))

	signAlg, deviceSig := "", ""
	if edge, err := edgesign.Sign(payloadHash); err != nil {
		return fmt.Errorf("assinatura borda: %w", err)
	} else if edge.Signature != "" {
		signAlg, deviceSig = edge.Alg, edge.Signature
	}

	latency, ledger, err := peercli.SubmitObservation(cfg, obsID, deviceID, payloadHash, recordedAt, signAlg, deviceSig)
	if err != nil {
		return err
	}
	return peercli.OutputJSON(obsID, latency, ledger)
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
