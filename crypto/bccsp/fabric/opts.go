package fabric

import "crypto"

const (
	// AlgorithmMLDSA65 identificador Fabric/BCCSP para ML-DSA-65 (Dilithium3).
	AlgorithmMLDSA65 = "ML-DSA-65"
)

// MLDSA65KeyGenOpts gera chaves ML-DSA-65 via liboqs.
type MLDSA65KeyGenOpts struct {
	EphemeralFlag bool
}

func (o *MLDSA65KeyGenOpts) Algorithm() string { return AlgorithmMLDSA65 }
func (o *MLDSA65KeyGenOpts) Ephemeral() bool   { return o.EphemeralFlag }

// MLDSA65PrivateKeyImportOpts importa SK bruta liboqs.
type MLDSA65PrivateKeyImportOpts struct {
	EphemeralFlag bool
}

func (o *MLDSA65PrivateKeyImportOpts) Algorithm() string { return AlgorithmMLDSA65 }
func (o *MLDSA65PrivateKeyImportOpts) Ephemeral() bool { return o.EphemeralFlag }

// MLDSA65PublicKeyImportOpts importa PK bruta liboqs.
type MLDSA65PublicKeyImportOpts struct {
	EphemeralFlag bool
}

func (o *MLDSA65PublicKeyImportOpts) Algorithm() string { return AlgorithmMLDSA65 }
func (o *MLDSA65PublicKeyImportOpts) Ephemeral() bool   { return o.EphemeralFlag }

// MLDSA65SignerOpts usa SHA-256 sobre o digest (padrão Fabric MSP).
type MLDSA65SignerOpts struct{}

func (o *MLDSA65SignerOpts) HashFunc() crypto.Hash { return crypto.SHA256 }
func (o *MLDSA65SignerOpts) String() string        { return AlgorithmMLDSA65 }
