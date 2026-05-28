// bccsp-smoke valida BCCSP ML-DSA-65 (KeyGen/Sign/Verify) — executar no host ou no container peer.
package main

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"

	"github.com/beneti/tcc-projeto-mldsa/crypto/bccsp/fabric"
	"github.com/hyperledger/fabric-lib-go/bccsp"
)

type memKS struct {
	m map[string]bccsp.Key
}

func newMemKS() *memKS { return &memKS{m: make(map[string]bccsp.Key)} }

func (ks *memKS) GetKey(ski []byte) (bccsp.Key, error) {
	if k, ok := ks.m[string(ski)]; ok {
		return k, nil
	}
	return nil, nil
}

func (ks *memKS) StoreKey(k bccsp.Key) error {
	ks.m[string(k.SKI())] = k
	return nil
}

func (ks *memKS) ReadOnly() bool { return false }

func main() {
	csp, err := fabric.NewMLDSABCCSP(newMemKS())
	if err != nil {
		fmt.Fprintf(os.Stderr, "NewMLDSABCCSP: %v\n", err)
		os.Exit(1)
	}
	k, err := csp.KeyGen(&fabric.MLDSA65KeyGenOpts{})
	if err != nil {
		fmt.Fprintf(os.Stderr, "KeyGen: %v\n", err)
		os.Exit(1)
	}
	digest := sha256.Sum256([]byte("bccsp-smoke-tcc"))
	sig, err := csp.Sign(k, digest[:], &fabric.MLDSA65SignerOpts{})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Sign: %v\n", err)
		os.Exit(1)
	}
	pub, err := k.PublicKey()
	if err != nil {
		fmt.Fprintf(os.Stderr, "PublicKey: %v\n", err)
		os.Exit(1)
	}
	ok, err := csp.Verify(pub, sig, digest[:], &fabric.MLDSA65SignerOpts{})
	if err != nil || !ok {
		fmt.Fprintf(os.Stderr, "Verify failed\n")
		os.Exit(1)
	}
	_ = json.NewEncoder(os.Stdout).Encode(map[string]any{
		"status":    "ok",
		"algorithm": fabric.AlgorithmMLDSA65,
		"sigBytes":  len(sig),
	})
}
