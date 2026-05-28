package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"flag"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/beneti/tcc-projeto-mldsa/crypto/bccsp"
	"github.com/beneti/tcc-projeto-mldsa/crypto/oqs"
)

const iterations = 50

func main() {
	outPath := flag.String("out", "", "arquivo markdown de saída")
	flag.Parse()

	var rows []string
	rows = append(rows, "# ECDSA P-256 vs ML-DSA-65 (liboqs)", "")
	rows = append(rows, fmt.Sprintf("Gerado em: %s · iterações: %d", time.Now().UTC().Format(time.RFC3339), iterations), "")
	rows = append(rows, "| Algoritmo | Chave pública (B) | Chave privada (B) | Assinatura (B) | KeyGen (ms) | Sign (ms) | Verify (ms) |", "")
	rows = append(rows, "|-----------|-------------------|-------------------|----------------|-------------|-----------|-------------|", "")

	ecdsaRow, err := benchECDSA()
	if err != nil {
		fmt.Fprintf(os.Stderr, "ECDSA: %v\n", err)
		os.Exit(1)
	}
	rows = append(rows, ecdsaRow)

	if oqs.Enabled() {
		mldsaRow, err := benchMLDSA()
		if err != nil {
			fmt.Fprintf(os.Stderr, "ML-DSA: %v\n", err)
			os.Exit(1)
		}
		rows = append(rows, mldsaRow)
	} else {
		rows = append(rows, "| ML-DSA-65 | — | — | — | — | — | — | *(liboqs não compilada)* |")
	}

	rows = append(rows, "", "## Notas", "")
	rows = append(rows, "- ML-DSA-65 ≡ Dilithium3 (NIST FIPS 204).")
	rows = append(rows, "- Tempos médios em amd64; repetir no Pi (arm64) para C2/C4.")
	rows = append(rows, "- Integração Fabric BCCSP: task 06 (`fabric/mldsa/`).")

	out := strings.Join(rows, "\n")
	if *outPath != "" {
		if err := os.WriteFile(*outPath, []byte(out+"\n"), 0o644); err != nil {
			fmt.Fprintf(os.Stderr, "write: %v\n", err)
			os.Exit(1)
		}
	}
	fmt.Print(out)
}

func benchECDSA() (string, error) {
	msg := []byte("benchmark-ecdsa-payload")
	var keyGen, sign, verify time.Duration
	var pubLen, privLen, sigLen int

	for i := 0; i < iterations; i++ {
		t0 := time.Now()
		key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
		if err != nil {
			return "", err
		}
		keyGen += time.Since(t0)

		digest := sha256.Sum256(msg)
		t1 := time.Now()
		sig, err := ecdsa.SignASN1(rand.Reader, key, digest[:])
		if err != nil {
			return "", err
		}
		sign += time.Since(t1)

		t2 := time.Now()
		if !ecdsa.VerifyASN1(&key.PublicKey, digest[:], sig) {
			return "", fmt.Errorf("ecdsa verify failed")
		}
		verify += time.Since(t2)

		pubLen = len(elliptic.Marshal(elliptic.P256(), key.PublicKey.X, key.PublicKey.Y))
		privLen = len(key.D.Bytes())
		sigLen = len(sig)
	}

	return fmt.Sprintf("| ECDSA P-256 | %d | %d | %d | %.3f | %.3f | %.3f |",
		pubLen, privLen, sigLen,
		ms(keyGen), ms(sign), ms(verify)), nil
}

func benchMLDSA() (string, error) {
	p, err := bccsp.NewMLDSAProvider()
	if err != nil {
		return "", err
	}
	msg := []byte("benchmark-mldsa-payload")
	var keyGen, sign, verify time.Duration
	pkLen, skLen, sigLen := p.KeySizes()

	var key *bccsp.Key
	for i := 0; i < iterations; i++ {
		t0 := time.Now()
		k, err := p.KeyGen()
		if err != nil {
			return "", err
		}
		keyGen += time.Since(t0)
		key = k

		t1 := time.Now()
		sig, err := p.Sign(key.PrivateKey, msg)
		if err != nil {
			return "", err
		}
		sign += time.Since(t1)

		t2 := time.Now()
		ok, err := p.Verify(key.PublicKey, msg, sig)
		if err != nil {
			return "", err
		}
		if !ok {
			return "", fmt.Errorf("mldsa verify failed")
		}
		verify += time.Since(t2)
		_ = sig
	}
	_ = key

	return fmt.Sprintf("| ML-DSA-65 | %d | %d | %d | %.3f | %.3f | %.3f |",
		pkLen, skLen, sigLen,
		ms(keyGen), ms(sign), ms(verify)), nil
}

func ms(d time.Duration) float64 {
	return float64(d.Milliseconds()) / float64(iterations)
}
