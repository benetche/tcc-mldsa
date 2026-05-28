package oqs_test

import (
	"testing"

	"github.com/beneti/tcc-projeto-mldsa/crypto/oqs"
)

func TestMLDSA65_RoundTrip(t *testing.T) {
	if !oqs.Enabled() {
		t.Skip("liboqs não instalada")
	}
	s, err := oqs.NewSigner()
	if err != nil {
		t.Fatal(err)
	}
	kp, err := s.KeyGen()
	if err != nil {
		t.Fatal(err)
	}
	msg := []byte("tcc-mldsa-roundtrip")
	sig, err := s.Sign(msg, kp.PrivateKey)
	if err != nil {
		t.Fatal(err)
	}
	ok, err := s.Verify(msg, sig, kp.PublicKey)
	if err != nil {
		t.Fatal(err)
	}
	if !ok {
		t.Fatal("verify failed")
	}
}
