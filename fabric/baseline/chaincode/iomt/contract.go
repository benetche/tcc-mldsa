package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// IoMTContract registra observações IoMT (hash/payload) no ledger.
type IoMTContract struct {
	contractapi.Contract
}

// Observation registro on-chain mínimo para benchmarks e ingestão FHIR.
type Observation struct {
	ID          string `json:"id"`
	DeviceID    string `json:"deviceId"`
	PayloadHash string `json:"payloadHash"`
	RecordedAt  string `json:"recordedAt"`
	Network     string `json:"network"`
}

// RegisterObservation grava uma observação IoMT (C1/C2 no Pi; futuro C3/C4 ESP32).
func (c *IoMTContract) RegisterObservation(ctx contractapi.TransactionContextInterface, id, deviceID, payloadHash, recordedAt string) error {
	if id == "" || deviceID == "" || payloadHash == "" {
		return fmt.Errorf("id, deviceID e payloadHash são obrigatórios")
	}
	key := fmt.Sprintf("OBS:%s", id)
	exists, err := ctx.GetStub().GetState(key)
	if err != nil {
		return fmt.Errorf("falha ao ler estado: %w", err)
	}
	if exists != nil {
		return fmt.Errorf("observação %s já existe", id)
	}
	network := os.Getenv("NETWORK_LABEL")
	if network == "" {
		network = "baseline"
	}
	obs := Observation{
		ID:          id,
		DeviceID:    deviceID,
		PayloadHash: payloadHash,
		RecordedAt:  recordedAt,
		Network:     network,
	}
	data, err := json.Marshal(obs)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(key, data)
}

// ReadObservation consulta uma observação pelo ID.
func (c *IoMTContract) ReadObservation(ctx contractapi.TransactionContextInterface, id string) (*Observation, error) {
	key := fmt.Sprintf("OBS:%s", id)
	data, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, err
	}
	if data == nil {
		return nil, fmt.Errorf("observação %s não encontrada", id)
	}
	var obs Observation
	if err := json.Unmarshal(data, &obs); err != nil {
		return nil, err
	}
	return &obs, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&IoMTContract{})
	if err != nil {
		log.Panicf("erro ao criar chaincode iomt: %v", err)
	}

	// Chaincode-as-a-Service (deployCCAAS / Docker no host)
	if addr := os.Getenv("CHAINCODE_SERVER_ADDRESS"); addr != "" {
		server := &shim.ChaincodeServer{
			CCID:    os.Getenv("CHAINCODE_ID"),
			Address: addr,
			CC:      chaincode,
			TLSProps: shim.TLSProperties{
				Disabled: true,
			},
		}
		if err := server.Start(); err != nil {
			log.Panicf("erro ao iniciar chaincode iomt (ccaas): %v", err)
		}
		return
	}

	// Modo clássico (peer inicia o chaincode em container)
	if err := chaincode.Start(); err != nil {
		log.Panicf("erro ao iniciar chaincode iomt: %v", err)
	}
}
