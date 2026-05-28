"""Cliente invoke/query Fabric (peer CLI) para ingestão FHIR."""

from __future__ import annotations

import json
import os
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path


@dataclass
class FabricConfig:
    fabric_samples: Path
    channel: str = "iomtchannel"
    chaincode: str = "iomt"
    msp_dir: Path | None = None
    peer_endpoint: str = "localhost:7051"

    @classmethod
    def from_env(cls) -> "FabricConfig":
        repo = Path(os.environ.get("REPO_ROOT", Path(__file__).resolve().parents[2]))
        samples = Path(os.environ.get("FABRIC_SAMPLES_DIR", repo / "fabric-samples"))
        tn = samples / "test-network"
        msp = Path(
            os.environ.get(
                "FABRIC_MSP_DIR",
                tn / "organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp",
            )
        )
        return cls(
            fabric_samples=samples,
            channel=os.environ.get("FABRIC_CHANNEL", "iomtchannel"),
            chaincode=os.environ.get("FABRIC_CHAINCODE", "iomt"),
            msp_dir=msp,
            peer_endpoint=os.environ.get("FABRIC_PEER_ENDPOINT", "localhost:7051"),
        )


def _peer_env(cfg: FabricConfig) -> dict[str, str]:
    tn = cfg.fabric_samples / "test-network"
    env = os.environ.copy()
    env["PATH"] = f"{cfg.fabric_samples / 'bin'}:{env.get('PATH', '')}"
    env["FABRIC_CFG_PATH"] = str(cfg.fabric_samples / "config")
    env["CORE_PEER_TLS_ENABLED"] = "true"
    env["CORE_PEER_LOCALMSPID"] = "Org1MSP"
    env["CORE_PEER_MSPCONFIGPATH"] = str(cfg.msp_dir)
    env["CORE_PEER_TLS_ROOTCERT_FILE"] = str(
        tn / "organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    )
    host = cfg.peer_endpoint.split(":")[0]
    if host not in ("localhost", "127.0.0.1"):
        env["CORE_PEER_ADDRESS"] = "peer0.org1.example.com:7051"
    else:
        env["CORE_PEER_ADDRESS"] = cfg.peer_endpoint
    return env


def register_fhir_observation(
    cfg: FabricConfig,
    obs_id: str,
    patient_id: str,
    device_id: str,
    loinc: str,
    value_qty: str,
    recorded_at: str,
    payload_hash: str,
    data_source: str,
    fhir_bytes: int,
) -> tuple[int, dict]:
    """Invoke RegisterFhirObservation; retorna (latency_ms, ledger_dict)."""
    tn = cfg.fabric_samples / "test-network"
    orderer_ca = (
        tn / "organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
    )
    peer1_tls = (
        tn / "organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
    )
    peer2_tls = (
        tn / "organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    )
    args = [
        obs_id,
        patient_id,
        device_id,
        loinc,
        value_qty,
        recorded_at,
        payload_hash,
        data_source,
        str(fhir_bytes),
    ]
    body = {"function": "RegisterFhirObservation", "Args": args}
    env = _peer_env(cfg)
    host = cfg.peer_endpoint.split(":")[0]
    if host not in ("localhost", "127.0.0.1"):
        peer1, peer2, orderer = "peer0.org1.example.com:7051", "peer0.org2.example.com:9051", "orderer.example.com:7050"
    else:
        peer1, peer2, orderer = "localhost:7051", "localhost:9051", "localhost:7050"

    start = time.time()
    subprocess.run(
        [
            "peer",
            "chaincode",
            "invoke",
            "-o",
            orderer,
            "--ordererTLSHostnameOverride",
            "orderer.example.com",
            "--tls",
            "--cafile",
            str(orderer_ca),
            "-C",
            cfg.channel,
            "-n",
            cfg.chaincode,
            "--peerAddresses",
            peer1,
            "--tlsRootCertFiles",
            str(peer1_tls),
            "--peerAddresses",
            peer2,
            "--tlsRootCertFiles",
            str(peer2_tls),
            "-c",
            json.dumps(body),
        ],
        env=env,
        check=True,
        capture_output=True,
    )
    latency_ms = int((time.time() - start) * 1000)
    time.sleep(2)
    q = subprocess.run(
        [
            "peer",
            "chaincode",
            "query",
            "-C",
            cfg.channel,
            "-n",
            cfg.chaincode,
            "-c",
            json.dumps({"function": "ReadObservation", "Args": [obs_id]}),
        ],
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )
    ledger = json.loads(q.stdout.strip())
    return latency_ms, ledger
