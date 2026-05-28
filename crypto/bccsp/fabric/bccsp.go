package fabric

import (
	"crypto/sha256"
	"hash"
	"reflect"

	"github.com/beneti/tcc-projeto-mldsa/crypto/oqs"
	"github.com/hyperledger/fabric-lib-go/bccsp"
	"github.com/hyperledger/fabric-lib-go/bccsp/sw"
	"github.com/pkg/errors"
)

// NewMLDSABCCSP cria BCCSP compatível com fabric-lib-go (SHA2-256 + ML-DSA-65).
func NewMLDSABCCSP(keyStore bccsp.KeyStore) (bccsp.BCCSP, error) {
	if !oqs.Enabled() {
		return nil, errors.New("liboqs ML-DSA-65 não disponível — rode build-liboqs.sh")
	}
	signer, err := oqs.NewSigner()
	if err != nil {
		return nil, err
	}
	if keyStore == nil {
		return nil, errors.New("keyStore required")
	}

	csp, err := sw.New(keyStore)
	if err != nil {
		return nil, err
	}

	registerMLDSAWrappers(csp, signer)

	// Hash SHA-256 (compatível com MSP Fabric)
	csp.AddWrapper(reflect.TypeOf(&bccsp.SHA256Opts{}), &hasher256{})
	csp.AddWrapper(reflect.TypeOf(&bccsp.SHAOpts{}), &hasher256{})

	return csp, nil
}

type hasher256 struct{}

func (h *hasher256) Hash(msg []byte, opts bccsp.HashOpts) ([]byte, error) {
	d := sha256.Sum256(msg)
	return d[:], nil
}

func (h *hasher256) GetHash(opts bccsp.HashOpts) (hash.Hash, error) {
	return sha256.New(), nil
}
