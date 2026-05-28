// sign-payload assina mensagem no dispositivo com ML-DSA-65 (liboqs).
// Saída JSON em stdout para o cliente edge (Pi / ESP32 via serial).
package main

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/beneti/tcc-projeto-mldsa/crypto/bccsp"
)

func main() {
	keyDir := flag.String("keydir", "", "diretório com mldsa.sk e mldsa.pk (hex)")
	message := flag.String("message", "", "payload a assinar (ex.: sha256:fixture)")
	flag.Parse()
	if *keyDir == "" || *message == "" {
		fmt.Fprintln(os.Stderr, "uso: sign-payload -keydir DIR -message PAYLOAD")
		os.Exit(2)
	}

	prov, err := bccsp.NewMLDSAProvider()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	skPath := filepath.Join(*keyDir, "mldsa.sk")
	pkPath := filepath.Join(*keyDir, "mldsa.pk")
	if err := os.MkdirAll(*keyDir, 0o700); err != nil {
		fail(err)
	}

	sk, pk, err := loadOrGenerate(prov, skPath, pkPath)
	if err != nil {
		fail(err)
	}
	_ = pk

	digest := sha256.Sum256([]byte(*message))
	sig, err := prov.Sign(sk, digest[:])
	if err != nil {
		fail(err)
	}
	out := map[string]any{
		"signAlg":           bccsp.AlgorithmMLDSA65,
		"deviceSignature":   base64.StdEncoding.EncodeToString(sig),
		"signatureBytes":    len(sig),
	}
	enc := json.NewEncoder(os.Stdout)
	if err := enc.Encode(out); err != nil {
		fail(err)
	}
}

func loadOrGenerate(prov *bccsp.MLDSAProvider, skPath, pkPath string) (sk, pk []byte, err error) {
	if data, err := os.ReadFile(skPath); err == nil {
		sk, err = hex.DecodeString(string(data))
		if err != nil {
			return nil, nil, err
		}
		pkData, err := os.ReadFile(pkPath)
		if err != nil {
			return nil, nil, err
		}
		pk, err = hex.DecodeString(string(pkData))
		return sk, pk, err
	}
	key, err := prov.KeyGen()
	if err != nil {
		return nil, nil, err
	}
	if err := os.WriteFile(skPath, []byte(hex.EncodeToString(key.PrivateKey)), 0o600); err != nil {
		return nil, nil, err
	}
	if err := os.WriteFile(pkPath, []byte(hex.EncodeToString(key.PublicKey)), 0o644); err != nil {
		return nil, nil, err
	}
	return key.PrivateKey, key.PublicKey, nil
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
