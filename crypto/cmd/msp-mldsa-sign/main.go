// msp-mldsa-sign assina digest no formato MSP de laboratório (ML-DSA-65 / liboqs).
// Equivalente a SigningIdentity.Sign do Fabric quando a identidade usa BCCSP MLDSA.
package main

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/beneti/tcc-projeto-mldsa/crypto/bccsp"
)

func main() {
	mspDir := flag.String("mspdir", "", "MSP lab (keystore/ + signcerts/)")
	message := flag.String("message", "", "mensagem ou preimage")
	obsID := flag.String("obs-id", "", "opcional: monta preimage MSP endorse")
	payloadHash := flag.String("payload-hash", "", "")
	recordedAt := flag.String("recorded-at", "", "")
	flag.Parse()

	if *mspDir == "" {
		fmt.Fprintln(os.Stderr, "uso: msp-mldsa-sign -mspdir DIR (-message MSG | -obs-id ID -payload-hash H -recorded-at TS)")
		os.Exit(2)
	}

	preimage := *message
	if preimage == "" {
		if *obsID == "" || *payloadHash == "" || *recordedAt == "" {
			fmt.Fprintln(os.Stderr, "informe -message ou o trio obs-id/payload-hash/recorded-at")
			os.Exit(2)
		}
		preimage = fmt.Sprintf("MSP-endorse-v1|%s|%s|%s", *obsID, *payloadHash, *recordedAt)
	}

	skPath := filepath.Join(*mspDir, "keystore", "priv_mldsa65_sk")
	pkPath := filepath.Join(*mspDir, "signcerts", "cert.pem")
	sk, err := os.ReadFile(skPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	pk, err := os.ReadFile(pkPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	prov, err := bccsp.NewMLDSAProvider()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	digest := sha256.Sum256([]byte(preimage))
	sig, err := prov.Sign(sk, digest[:])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	ok, err := prov.Verify(pk, digest[:], sig)
	if err != nil || !ok {
		fmt.Fprintln(os.Stderr, "verificação local falhou")
		os.Exit(1)
	}

	out := map[string]any{
		"mspSignAlg":           bccsp.AlgorithmMLDSA65,
		"mspSignature":         base64.StdEncoding.EncodeToString(sig),
		"mspSignatureBytes":    len(sig),
		"mspPreimage":          preimage,
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	_ = enc.Encode(out)
}
