// Package edgesign assina payload no dispositivo de borda (C1 ECDSA / C2 ML-DSA).
package edgesign

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math/big"
	"os"
	"os/exec"
	"path/filepath"
)

// Result assinatura no dispositivo.
type Result struct {
	Alg       string `json:"signAlg"`
	Signature string `json:"deviceSignature"` // base64
	SigBytes  int    `json:"signatureBytes"`
}

// Sign assina o payloadHash conforme cenário (baseline→ECDSA, mldsa→ML-DSA).
func Sign(payloadHash string) (Result, error) {
	alg := os.Getenv("IOMT_EDGE_SIGN")
	if alg == "" {
		switch os.Getenv("FABRIC_NETWORK") {
		case "mldsa":
			alg = "ML-DSA-65"
		default:
			alg = "ECDSA-P256"
		}
	}
	switch alg {
	case "ECDSA-P256", "ecdsa":
		return signECDSA(payloadHash)
	case "ML-DSA-65", "mldsa":
		return signMLDSA(payloadHash)
	case "none":
		return Result{}, nil
	default:
		return Result{}, fmt.Errorf("IOMT_EDGE_SIGN não suportado: %s", alg)
	}
}

func signECDSA(payloadHash string) (Result, error) {
	dir := keyDir()
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return Result{}, err
	}
	keyPath := filepath.Join(dir, "ecdsa-p256.json")
	key, err := loadOrCreateECDSA(keyPath)
	if err != nil {
		return Result{}, err
	}
	digest := sha256.Sum256([]byte(payloadHash))
	sig, err := ecdsa.SignASN1(rand.Reader, key, digest[:])
	if err != nil {
		return Result{}, err
	}
	b64 := base64.StdEncoding.EncodeToString(sig)
	return Result{Alg: "ECDSA-P256", Signature: b64, SigBytes: len(sig)}, nil
}

type ecdsaKeyJSON struct {
	D string `json:"d"`
	X string `json:"x"`
	Y string `json:"y"`
}

func loadOrCreateECDSA(path string) (*ecdsa.PrivateKey, error) {
	if data, err := os.ReadFile(path); err == nil {
		var stored ecdsaKeyJSON
		if err := json.Unmarshal(data, &stored); err != nil {
			return nil, err
		}
		d, _ := new(big.Int).SetString(stored.D, 16)
		x, _ := new(big.Int).SetString(stored.X, 16)
		y, _ := new(big.Int).SetString(stored.Y, 16)
		return &ecdsa.PrivateKey{
			PublicKey: ecdsa.PublicKey{Curve: elliptic.P256(), X: x, Y: y},
			D:         d,
		}, nil
	}
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, err
	}
	stored := ecdsaKeyJSON{
		D: hex.EncodeToString(key.D.Bytes()),
		X: hex.EncodeToString(key.X.Bytes()),
		Y: hex.EncodeToString(key.Y.Bytes()),
	}
	data, _ := json.Marshal(stored)
	_ = os.WriteFile(path, data, 0o600)
	return key, nil
}

func signMLDSA(payloadHash string) (Result, error) {
	bin := os.Getenv("IOMT_SIGN_PAYLOAD_BIN")
	if bin == "" {
		base := os.Getenv("TCC_IOMT_HOME")
		if base == "" {
			base = filepath.Join(os.Getenv("HOME"), "tcc-iomt")
		}
		bin = filepath.Join(base, "bin", "sign-payload-mldsa")
	}
	if _, err := os.Stat(bin); err != nil {
		return Result{}, fmt.Errorf("binário ML-DSA ausente em %s (rode deploy-to-pi.sh)", bin)
	}
	keyDir := os.Getenv("IOMT_MLDSA_KEY_DIR")
	if keyDir == "" {
		keyDir = filepath.Join(keyDirBase(), "mldsa-65")
	}
	cmd := exec.Command(bin, "-keydir", keyDir, "-message", payloadHash)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return Result{}, fmt.Errorf("sign-payload-mldsa: %w\n%s", err, out)
	}
	var res struct {
		SignAlg           string `json:"signAlg"`
		DeviceSignature string `json:"deviceSignature"`
		SignatureBytes  int    `json:"signatureBytes"`
	}
	if err := json.Unmarshal(out, &res); err != nil {
		return Result{}, err
	}
	return Result{Alg: res.SignAlg, Signature: res.DeviceSignature, SigBytes: res.SignatureBytes}, nil
}

func keyDir() string {
	if d := os.Getenv("IOMT_EDGE_KEY_DIR"); d != "" {
		return d
	}
	return filepath.Join(keyDirBase(), "ecdsa")
}

func keyDirBase() string {
	if d := os.Getenv("IOMT_EDGE_KEY_DIR"); d != "" {
		return filepath.Dir(d)
	}
	if r := os.Getenv("REPO_ROOT"); r != "" {
		return filepath.Join(r, "edge", "raspberry-pi", "keys")
	}
	return filepath.Join(".", "keys")
}
