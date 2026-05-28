package fabric

import (
	"reflect"

	"github.com/beneti/tcc-projeto-mldsa/crypto/oqs"
	"github.com/hyperledger/fabric-lib-go/bccsp"
	"github.com/hyperledger/fabric-lib-go/bccsp/sw"
	"github.com/pkg/errors"
)

type mldsaKeyGenerator struct {
	signer *oqs.Signer
}

func (kg *mldsaKeyGenerator) KeyGen(opts bccsp.KeyGenOpts) (bccsp.Key, error) {
	if reflect.TypeOf(opts) != reflect.TypeOf(&MLDSA65KeyGenOpts{}) {
		return nil, errors.Errorf("unsupported keygen opts %T", opts)
	}
	kp, err := kg.signer.KeyGen()
	if err != nil {
		return nil, err
	}
	return &mldsaPrivateKey{sk: kp.PrivateKey, pk: kp.PublicKey, signer: kg.signer}, nil
}

type mldsaPrivateKeyImporter struct {
	signer *oqs.Signer
}

func (ki *mldsaPrivateKeyImporter) KeyImport(raw interface{}, opts bccsp.KeyImportOpts) (bccsp.Key, error) {
	if reflect.TypeOf(opts) != reflect.TypeOf(&MLDSA65PrivateKeyImportOpts{}) {
		return nil, errors.Errorf("unsupported import opts %T", opts)
	}
	sk, ok := raw.([]byte)
	if !ok {
		return nil, errors.New("raw must be []byte secret key")
	}
	_, skLen, _ := ki.signer.Sizes()
	if len(sk) != skLen {
		return nil, errors.Errorf("invalid sk length %d (want %d)", len(sk), skLen)
	}
	// PK não está no import; caller deve usar KeyPair completo via KeyGen.
	return &mldsaPrivateKey{sk: sk, signer: ki.signer}, nil
}

// registerMLDSAWrappers registra primitivas ML-DSA no CSP software Fabric.
func registerMLDSAWrappers(csp *sw.CSP, signer *oqs.Signer) {
	kg := &mldsaKeyGenerator{signer: signer}
	csp.AddWrapper(reflect.TypeOf(&MLDSA65KeyGenOpts{}), kg)
	csp.AddWrapper(reflect.TypeOf(&mldsaPrivateKey{}), &mldsaSigner{signer: signer})
	csp.AddWrapper(reflect.TypeOf(&mldsaPublicKey{}), &mldsaVerifier{signer: signer})
	csp.AddWrapper(reflect.TypeOf(&mldsaPrivateKey{}), &mldsaVerifier{signer: signer})
	csp.AddWrapper(reflect.TypeOf(&MLDSA65PrivateKeyImportOpts{}), &mldsaPrivateKeyImporter{signer: signer})
}

type mldsaSigner struct {
	signer *oqs.Signer
}

func (s *mldsaSigner) Sign(k bccsp.Key, digest []byte, opts bccsp.SignerOpts) ([]byte, error) {
	priv, ok := k.(*mldsaPrivateKey)
	if !ok {
		return nil, errors.New("invalid key type for ML-DSA sign")
	}
	return s.signer.Sign(digest, priv.sk)
}

type mldsaVerifier struct {
	signer *oqs.Signer
}

func (v *mldsaVerifier) Verify(k bccsp.Key, signature, digest []byte, opts bccsp.SignerOpts) (bool, error) {
	var pk []byte
	switch key := k.(type) {
	case *mldsaPublicKey:
		pk = key.pk
	case *mldsaPrivateKey:
		pk = key.pk
	default:
		return false, errors.New("invalid key type for ML-DSA verify")
	}
	if len(pk) == 0 {
		return false, errors.New("public key not set on private key")
	}
	return v.signer.Verify(digest, signature, pk)
}
