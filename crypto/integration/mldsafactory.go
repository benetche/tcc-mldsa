/*
Copyright TCC IoMT — ML-DSA BCCSP factory para Hyperledger Fabric.
*/
package factory

import (
	"github.com/hyperledger/fabric/bccsp"
	"github.com/hyperledger/fabric/bccsp/mldsa"
	"github.com/hyperledger/fabric/bccsp/sw"
	"github.com/pkg/errors"
)

const MLDSAFactoryName = "MLDSA"

// MLDSAFactory fabrica BCCSP com assinaturas ML-DSA-65 (liboqs).
type MLDSAFactory struct{}

func (f *MLDSAFactory) Name() string { return MLDSAFactoryName }

func (f *MLDSAFactory) Get(config *FactoryOpts) (bccsp.BCCSP, error) {
	if config == nil || config.MLDSA == nil {
		return nil, errors.New("invalid config: MLDSA section required")
	}
	opts := config.MLDSA
	var ks bccsp.KeyStore
	switch {
	case opts.FileKeystore != nil:
		fks, err := sw.NewFileBasedKeyStore(nil, opts.FileKeystore.KeyStorePath, false)
		if err != nil {
			return nil, errors.Wrapf(err, "mldsa file keystore")
		}
		ks = fks
	default:
		ks = sw.NewDummyKeyStore()
	}
	return mldsa.NewMLDSABCCSP(ks)
}

// MLDSAOpts opções do provedor ML-DSA.
type MLDSAOpts struct {
	FileKeystore *FileKeystoreOpts `json:"filekeystore,omitempty" yaml:"FileKeyStore,omitempty"`
}
