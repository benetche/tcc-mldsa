# Criptografia — Pilar 2 (ML-DSA + liboqs)

Integração **liboqs** com provedor de assinatura alinhado ao **BCCSP** do Hyperledger Fabric.

| Item | Valor |
|------|--------|
| Algoritmo | **ML-DSA-65** (Dilithium3, NIST FIPS 204) |
| Biblioteca | [liboqs](https://github.com/open-quantum-safe/liboqs) **0.12.0** |
| Baseline | ECDSA P-256 (referência em benchmarks) |

## Estrutura

```
crypto/
├── oqs/              # binding CGO liboqs (sign/verify/keygen)
├── bccsp/            # provedor ML-DSA (task 06 → Fabric BCCSP)
├── cmd/benchmark-crypto/
├── bccsp.yaml.example
├── scripts/
│   ├── build-liboqs.sh
│   ├── test-mldsa.sh
│   └── benchmark-crypto.sh
└── lib/              # install prefix (gitignored)
```

## Build liboqs

```bash
sudo apt install -y build-essential cmake git ninja-build pkg-config
./crypto/scripts/build-liboqs.sh
```

Variáveis (adicionar ao shell ou `fabric/mldsa` depois):

```bash
export LIBOQS_PREFIX="$(pwd)/crypto/lib"
export PKG_CONFIG_PATH="$LIBOQS_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$LIBOQS_PREFIX/lib:$LD_LIBRARY_PATH"
export CGO_ENABLED=1
```

## Testes

```bash
./crypto/scripts/test-mldsa.sh
```

## Benchmark ECDSA vs ML-DSA

```bash
./crypto/scripts/benchmark-crypto.sh
# → crypto/docs/ecdsa-vs-mldsa.md
```

## ARM64 (Raspberry Pi)

Recompilar liboqs **no Pi** (mesmo script) ou cross-compile com toolchain adequada. Validar cedo para C2:

```bash
# No Pi, após copiar crypto/
LIBOQS_PREFIX=~/tcc-iomt/crypto/lib ./scripts/build-liboqs.sh
```

## Próximo passo (task 06)

- Registrar factory no BCCSP do Fabric
- `fabric/mldsa/` espelhando `fabric/baseline/`
- Smoke **C2** no Pi (`edge/raspberry-pi`)

## Referências

- [decisoes-stack.md](../docs/decisoes-stack.md) §3
- Task: `.cursor/tasks/05-liboqs-bccsp-mldsa.md`
