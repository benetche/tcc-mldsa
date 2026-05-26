# Chaincode-as-a-Service — IoMT (Fabric baseline)
FROM golang:1.22-alpine AS builder

WORKDIR /chaincode
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /chaincode/iomt .

FROM alpine:3.19
ARG CC_SERVER_PORT=9999
RUN apk add --no-cache ca-certificates
WORKDIR /chaincode
COPY --from=builder /chaincode/iomt .
EXPOSE ${CC_SERVER_PORT}
ENV CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CC_SERVER_PORT}
ENTRYPOINT ["/chaincode/iomt"]
