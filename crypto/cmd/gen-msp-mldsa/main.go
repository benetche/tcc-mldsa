package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/beneti/tcc-projeto-mldsa/crypto/bccsp"
)

func main() {
	out := flag.String("out", "", "diretório MSP de saída")
	flag.Parse()
	if *out == "" {
		fmt.Fprintln(os.Stderr, "usage: gen-msp-mldsa -out <dir>")
		os.Exit(1)
	}

	p, err := bccsp.NewMLDSAProvider()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	key, err := p.KeyGen()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	ksDir := filepath.Join(*out, "keystore")
	scDir := filepath.Join(*out, "signcerts")
	if err := os.MkdirAll(ksDir, 0o700); err != nil {
		panic(err)
	}
	if err := os.MkdirAll(scDir, 0o755); err != nil {
		panic(err)
	}

	skPath := filepath.Join(ksDir, "priv_mldsa65_sk")
	pkPath := filepath.Join(scDir, "cert.pem")
	if err := os.WriteFile(skPath, key.PrivateKey, 0o600); err != nil {
		panic(err)
	}
	if err := os.WriteFile(pkPath, key.PublicKey, 0o644); err != nil {
		panic(err)
	}
	fmt.Printf("ML-DSA-65 keys written to %s\n", *out)
}
