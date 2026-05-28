//go:build !cgo

package oqs

import "errors"

const AlgorithmMLDSA65 = "ML-DSA-65"

var errNoCGO = errors.New("oqs: requer CGO e liboqs (build-liboqs.sh)")

func Enabled() bool { return false }

type KeyPair struct {
	PublicKey  []byte
	PrivateKey []byte
}

type Signer struct{}

func NewSigner() (*Signer, error) { return nil, errNoCGO }
func (s *Signer) KeyGen() (*KeyPair, error) { return nil, errNoCGO }
func (s *Signer) Sign([]byte, []byte) ([]byte, error) { return nil, errNoCGO }
func (s *Signer) Verify([]byte, []byte, []byte) (bool, error) { return false, errNoCGO }
func (s *Signer) Sizes() (int, int, int) { return 0, 0, 0 }
