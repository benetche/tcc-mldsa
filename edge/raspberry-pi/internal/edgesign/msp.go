package edgesign

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// MspMldsaSign gera assinatura MSP ML-DSA-65 (BCCSP lab) para gravar on-chain.
func MspMldsaSign(obsID, payloadHash, recordedAt string) (alg, signature string, err error) {
	bin := os.Getenv("IOMT_MSP_SIGN_BIN")
	if bin == "" {
		base := os.Getenv("TCC_IOMT_HOME")
		if base == "" {
			base = filepath.Join(os.Getenv("HOME"), "tcc-iomt")
		}
		bin = filepath.Join(base, "bin", "msp-mldsa-sign")
	}
	mspDir := os.Getenv("IOMT_MLDSA_MSP_DIR")
	if mspDir == "" {
		mspDir = filepath.Join(os.Getenv("REPO_ROOT"), "fabric", "mldsa", "lab-msp", "org1", "user1")
	}
	cmd := exec.Command(bin,
		"-mspdir", mspDir,
		"-obs-id", obsID,
		"-payload-hash", payloadHash,
		"-recorded-at", recordedAt,
	)
	cmd.Env = append(os.Environ(), fmt.Sprintf("LD_LIBRARY_PATH=%s", os.Getenv("LD_LIBRARY_PATH")))
	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", "", fmt.Errorf("msp-mldsa-sign: %w\n%s", err, out)
	}
	var res struct {
		MspSignAlg    string `json:"mspSignAlg"`
		MspSignature  string `json:"mspSignature"`
	}
	if err := json.Unmarshal(out, &res); err != nil {
		return "", "", err
	}
	return res.MspSignAlg, res.MspSignature, nil
}
