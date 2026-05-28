package bccsp_test

import (
	"crypto/sha256"
	"testing"

	"github.com/beneti/tcc-projeto-mldsa/crypto/bccsp"
	"github.com/beneti/tcc-projeto-mldsa/crypto/oqs"
)

func requireMLDSA(t *testing.T) *bccsp.MLDSAProvider {
	t.Helper()
	if !oqs.Enabled() {
		t.Skip("liboqs ML-DSA-65 não disponível — rode crypto/scripts/build-liboqs.sh")
	}
	p, err := bccsp.NewMLDSAProvider()
	if err != nil {
		t.Fatalf("NewMLDSAProvider: %v", err)
	}
	return p
}

func TestMLDSA_KeyGenSignVerify(t *testing.T) {
	p := requireMLDSA(t)
	key, err := p.KeyGen()
	if err != nil {
		t.Fatal(err)
	}
	msg := []byte("iomt-payload-hash-smoke-pqc")
	sig, err := p.Sign(key.PrivateKey, msg)
	if err != nil {
		t.Fatal(err)
	}
	ok, err := p.Verify(key.PublicKey, msg, sig)
	if err != nil {
		t.Fatal(err)
	}
	if !ok {
		t.Fatal("assinatura inválida")
	}
}

func TestMLDSA_VerifyFailsOnTamper(t *testing.T) {
	p := requireMLDSA(t)
	key, _ := p.KeyGen()
	msg := []byte("tamper-test")
	sig, _ := p.Sign(key.PrivateKey, msg)
	msg[0] ^= 0xff
	ok, err := p.Verify(key.PublicKey, msg, sig)
	if err != nil {
		t.Fatal(err)
	}
	if ok {
		t.Fatal("esperava falha de verificação")
	}
}

func TestMLDSA_SignDigest(t *testing.T) {
	p := requireMLDSA(t)
	key, _ := p.KeyGen()
	payload := []byte("observation-fhir-fixture")
	digest := sha256.Sum256(payload)
	sig, err := p.Sign(key.PrivateKey, digest[:])
	if err != nil {
		t.Fatal(err)
	}
	ok, err := p.Verify(key.PublicKey, digest[:], sig)
	if err != nil || !ok {
		t.Fatalf("verify digest: ok=%v err=%v", ok, err)
	}
}

func TestMLDSA_KeySizes(t *testing.T) {
	p := requireMLDSA(t)
	pk, sk, sig := p.KeySizes()
	if pk != 1952 || sk != 4032 || sig != 3309 {
		t.Fatalf("tamanhos ML-DSA-65: pk=%d sk=%d sig=%d", pk, sk, sig)
	}
}
