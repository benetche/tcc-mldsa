//go:build cgo

// Package oqs expõe ML-DSA-65 via liboqs (Open Quantum Safe).
package oqs

/*
#cgo pkg-config: liboqs
#include <oqs/oqs.h>
#include <stdlib.h>
*/
import "C"
import (
	"errors"
	"fmt"
	"unsafe"
)

const AlgorithmMLDSA65 = "ML-DSA-65"

// Enabled indica se liboqs foi linkada (ML-DSA-65 disponível).
func Enabled() bool {
	name := C.CString(AlgorithmMLDSA65)
	defer C.free(unsafe.Pointer(name))
	return C.OQS_SIG_alg_is_enabled(name) == 1
}

// KeyPair chaves ML-DSA-65 (formato liboqs).
type KeyPair struct {
	PublicKey  []byte
	PrivateKey []byte
}

// Signer operações de assinatura ML-DSA-65.
type Signer struct {
	pkLen int
	skLen int
	sigLen int
}

// NewSigner cria um signer ML-DSA-65.
func NewSigner() (*Signer, error) {
	if !Enabled() {
		return nil, errors.New("oqs: ML-DSA-65 não habilitado — execute crypto/scripts/build-liboqs.sh")
	}
	cName := C.CString(AlgorithmMLDSA65)
	defer C.free(unsafe.Pointer(cName))
	sig := C.OQS_SIG_new(cName)
	if sig == nil {
		return nil, fmt.Errorf("oqs: algoritmo %s indisponível", AlgorithmMLDSA65)
	}
	defer C.OQS_SIG_free(sig)
	return &Signer{
		pkLen:  int(sig.length_public_key),
		skLen:  int(sig.length_secret_key),
		sigLen: int(sig.length_signature),
	}, nil
}

// KeyGen gera par de chaves ML-DSA-65.
func (s *Signer) KeyGen() (*KeyPair, error) {
	cName := C.CString(AlgorithmMLDSA65)
	defer C.free(unsafe.Pointer(cName))
	sig := C.OQS_SIG_new(cName)
	if sig == nil {
		return nil, errors.New("oqs: OQS_SIG_new falhou")
	}
	defer C.OQS_SIG_free(sig)

	pk := make([]byte, s.pkLen)
	sk := make([]byte, s.skLen)
	if rc := C.OQS_SIG_keypair(sig, (*C.uint8_t)(unsafe.Pointer(&pk[0])), (*C.uint8_t)(unsafe.Pointer(&sk[0]))); rc != C.OQS_SUCCESS {
		return nil, fmt.Errorf("oqs: keypair falhou (rc=%d)", int(rc))
	}
	return &KeyPair{PublicKey: pk, PrivateKey: sk}, nil
}

// Sign assina a mensagem (ou digest pré-computado) com a chave privada.
func (s *Signer) Sign(message, privateKey []byte) ([]byte, error) {
	if len(privateKey) != s.skLen {
		return nil, fmt.Errorf("oqs: chave privada inválida (%d bytes, esperado %d)", len(privateKey), s.skLen)
	}
	cName := C.CString(AlgorithmMLDSA65)
	defer C.free(unsafe.Pointer(cName))
	sig := C.OQS_SIG_new(cName)
	if sig == nil {
		return nil, errors.New("oqs: OQS_SIG_new falhou")
	}
	defer C.OQS_SIG_free(sig)

	signature := make([]byte, s.sigLen)
	var sigLen C.size_t
	msgPtr := (*C.uint8_t)(unsafe.Pointer(&message[0]))
	skPtr := (*C.uint8_t)(unsafe.Pointer(&privateKey[0]))
	sigPtr := (*C.uint8_t)(unsafe.Pointer(&signature[0]))

	if rc := C.OQS_SIG_sign(sig, sigPtr, &sigLen, msgPtr, C.size_t(len(message)), skPtr); rc != C.OQS_SUCCESS {
		return nil, fmt.Errorf("oqs: sign falhou (rc=%d)", int(rc))
	}
	return signature[:sigLen], nil
}

// Verify valida assinatura ML-DSA-65.
func (s *Signer) Verify(message, signature, publicKey []byte) (bool, error) {
	if len(publicKey) != s.pkLen {
		return false, fmt.Errorf("oqs: chave pública inválida (%d bytes, esperado %d)", len(publicKey), s.pkLen)
	}
	cName := C.CString(AlgorithmMLDSA65)
	defer C.free(unsafe.Pointer(cName))
	sig := C.OQS_SIG_new(cName)
	if sig == nil {
		return false, errors.New("oqs: OQS_SIG_new falhou")
	}
	defer C.OQS_SIG_free(sig)

	msgPtr := (*C.uint8_t)(unsafe.Pointer(&message[0]))
	sigPtr := (*C.uint8_t)(unsafe.Pointer(&signature[0]))
	pkPtr := (*C.uint8_t)(unsafe.Pointer(&publicKey[0]))

	rc := C.OQS_SIG_verify(sig, msgPtr, C.size_t(len(message)), sigPtr, C.size_t(len(signature)), pkPtr)
	switch rc {
	case C.OQS_SUCCESS:
		return true, nil
	case C.OQS_ERROR:
		return false, nil
	default:
		return false, fmt.Errorf("oqs: verify erro interno (rc=%d)", int(rc))
	}
}

// Sizes retorna tamanhos fixos ML-DSA-65 (bytes).
func (s *Signer) Sizes() (pubKey, privKey, signature int) {
	return s.pkLen, s.skLen, s.sigLen
}
