// Package bccsp fornece um provedor de assinatura ML-DSA alinhado ao perfil Fabric (Pilar 2).
// Integração completa com github.com/hyperledger/fabric-lib-go/bccsp é a task 06.
package bccsp

import (
	"errors"
	"fmt"

	"github.com/beneti/tcc-projeto-mldsa/crypto/oqs"
)

// Algoritmos suportados neste provedor (task 05).
const (
	AlgorithmMLDSA65 = oqs.AlgorithmMLDSA65
	AlgorithmECDSA   = "ECDSA-P256" // baseline de referência (stdlib)
)

// Key material de assinatura exportável.
type Key struct {
	Algorithm  string
	PublicKey  []byte
	PrivateKey []byte // vazio se apenas chave pública
}

// Provider operações de assinatura para integração futura ao Fabric BCCSP.
type Provider interface {
	Algorithm() string
	KeyGen() (*Key, error)
	Sign(privateKey, message []byte) ([]byte, error)
	Verify(publicKey, message, signature []byte) (bool, error)
	KeySizes() (pubKey, privKey, signature int)
}

// MLDSAProvider implementa ML-DSA-65 via liboqs.
type MLDSAProvider struct {
	signer *oqs.Signer
}

// NewMLDSAProvider cria o provedor ML-DSA-65.
func NewMLDSAProvider() (*MLDSAProvider, error) {
	s, err := oqs.NewSigner()
	if err != nil {
		return nil, fmt.Errorf("bccsp: %w", err)
	}
	return &MLDSAProvider{signer: s}, nil
}

// Algorithm retorna o identificador do algoritmo.
func (p *MLDSAProvider) Algorithm() string { return AlgorithmMLDSA65 }

// KeyGen gera par de chaves ML-DSA-65.
func (p *MLDSAProvider) KeyGen() (*Key, error) {
	kp, err := p.signer.KeyGen()
	if err != nil {
		return nil, err
	}
	return &Key{
		Algorithm:  AlgorithmMLDSA65,
		PublicKey:  kp.PublicKey,
		PrivateKey: kp.PrivateKey,
	}, nil
}

// Sign assina bytes (mensagem ou digest SHA-256 pré-computado).
func (p *MLDSAProvider) Sign(privateKey, message []byte) ([]byte, error) {
	if len(privateKey) == 0 {
		return nil, errors.New("bccsp: chave privada vazia")
	}
	if len(message) == 0 {
		return nil, errors.New("bccsp: mensagem vazia")
	}
	return p.signer.Sign(message, privateKey)
}

// Verify valida assinatura ML-DSA-65.
func (p *MLDSAProvider) Verify(publicKey, message, signature []byte) (bool, error) {
	if len(publicKey) == 0 {
		return false, errors.New("bccsp: chave pública vazia")
	}
	return p.signer.Verify(message, signature, publicKey)
}

// KeySizes retorna tamanhos em bytes.
func (p *MLDSAProvider) KeySizes() (int, int, int) {
	return p.signer.Sizes()
}
