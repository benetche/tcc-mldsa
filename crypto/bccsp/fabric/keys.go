package fabric

import (
	"crypto/sha256"
	"fmt"

	"github.com/beneti/tcc-projeto-mldsa/crypto/oqs"
	"github.com/hyperledger/fabric-lib-go/bccsp"
)

type mldsaPrivateKey struct {
	sk     []byte
	pk     []byte
	signer *oqs.Signer
}

type mldsaPublicKey struct {
	pk     []byte
	signer *oqs.Signer
}

func (k *mldsaPrivateKey) Bytes() ([]byte, error) {
	if k.sk == nil {
		return nil, fmt.Errorf("mldsa private key not exportable")
	}
	out := make([]byte, len(k.sk))
	copy(out, k.sk)
	return out, nil
}

func (k *mldsaPrivateKey) SKI() []byte {
	if k.pk == nil {
		return nil
	}
	h := sha256.Sum256(k.pk)
	return h[:]
}

func (k *mldsaPrivateKey) Symmetric() bool { return false }
func (k *mldsaPrivateKey) Private() bool   { return true }

func (k *mldsaPrivateKey) PublicKey() (bccsp.Key, error) {
	return &mldsaPublicKey{pk: k.pk, signer: k.signer}, nil
}

func (k *mldsaPublicKey) Bytes() ([]byte, error) {
	if k.pk == nil {
		return nil, fmt.Errorf("mldsa public key empty")
	}
	out := make([]byte, len(k.pk))
	copy(out, k.pk)
	return out, nil
}

func (k *mldsaPublicKey) SKI() []byte {
	if k.pk == nil {
		return nil
	}
	h := sha256.Sum256(k.pk)
	return h[:]
}

func (k *mldsaPublicKey) Symmetric() bool { return false }
func (k *mldsaPublicKey) Private() bool   { return false }

func (k *mldsaPublicKey) PublicKey() (bccsp.Key, error) {
	return k, nil
}
