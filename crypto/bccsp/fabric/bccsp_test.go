package fabric_test

import (
	"crypto/sha256"
	"testing"

	"github.com/beneti/tcc-projeto-mldsa/crypto/bccsp/fabric"
	"github.com/beneti/tcc-projeto-mldsa/crypto/oqs"
	"github.com/hyperledger/fabric-lib-go/bccsp"
)

type memKS struct {
	m map[string]bccsp.Key
}

func newMemKS() *memKS { return &memKS{m: make(map[string]bccsp.Key)} }

func (ks *memKS) GetKey(ski []byte) (bccsp.Key, error) {
	k, ok := ks.m[string(ski)]
	if !ok {
		return nil, nil
	}
	return k, nil
}

func (ks *memKS) StoreKey(k bccsp.Key) error {
	ks.m[string(k.SKI())] = k
	return nil
}

func (ks *memKS) ReadOnly() bool { return false }

func TestFabricMLDSABCCSP_KeyGenSignVerify(t *testing.T) {
	if !oqs.Enabled() {
		t.Skip("liboqs não instalada")
	}
	csp, err := fabric.NewMLDSABCCSP(newMemKS())
	if err != nil {
		t.Fatal(err)
	}
	k, err := csp.KeyGen(&fabric.MLDSA65KeyGenOpts{})
	if err != nil {
		t.Fatal(err)
	}
	msg := []byte("fabric-msp-digest-test")
	digest := sha256.Sum256(msg)
	sig, err := csp.Sign(k, digest[:], &fabric.MLDSA65SignerOpts{})
	if err != nil {
		t.Fatal(err)
	}
	pub, err := k.PublicKey()
	if err != nil {
		t.Fatal(err)
	}
	ok, err := csp.Verify(pub, sig, digest[:], &fabric.MLDSA65SignerOpts{})
	if err != nil {
		t.Fatal(err)
	}
	if !ok {
		t.Fatal("verify failed")
	}
}

func TestFabricMLDSABCCSP_Hash(t *testing.T) {
	if !oqs.Enabled() {
		t.Skip("liboqs não instalada")
	}
	csp, err := fabric.NewMLDSABCCSP(newMemKS())
	if err != nil {
		t.Fatal(err)
	}
	h, err := csp.Hash([]byte("abc"), &bccsp.SHA256Opts{})
	if err != nil {
		t.Fatal(err)
	}
	if len(h) != sha256.Size {
		t.Fatalf("hash len %d", len(h))
	}
}
