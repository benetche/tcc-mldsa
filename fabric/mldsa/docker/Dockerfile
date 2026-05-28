# Peer/orderer Fabric 2.5 com BCCSP ML-DSA (liboqs) — laboratório TCC
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libstdc++6 docker.io \
    && rm -rf /var/lib/apt/lists/*

# liboqs (copiada pelo build-peer-image.sh em docker/dist/lib/)
COPY dist/lib/ /usr/local/lib/oqs/
ENV LD_LIBRARY_PATH=/usr/local/lib/oqs

# Binários compilados com build-fabric-mldsa.sh
COPY dist/bin/peer /usr/local/bin/peer
COPY dist/bin/orderer /usr/local/bin/orderer
COPY dist/ccaas_builder /opt/hyperledger/ccaas_builder

RUN chmod +x /usr/local/bin/peer /usr/local/bin/orderer \
    && chmod -R +x /opt/hyperledger/ccaas_builder/bin 2>/dev/null || true

WORKDIR /root
# command do compose: peer node start (peer no PATH)
ENV PATH=/usr/local/bin:${PATH}
