GOLANGCI_LINT_CACHE?=/tmp/praktikum-golangci-lint-cache
CONFIG_FILE=not_set
MASTER_KEY=change_me

.PHONY: golangci-lint-run
golangci-lint-run: _golangci-lint-rm-unformatted-report

.PHONY: _golangci-lint-reports-mkdir
_golangci-lint-reports-mkdir:
	mkdir -p ./golangci-lint

.PHONY: _golangci-lint-run
_golangci-lint-run: _golangci-lint-reports-mkdir
	-docker run --rm \
    -v $(shell pwd):/app \
    -v $(GOLANGCI_LINT_CACHE):/root/.cache \
    -w /app \
    golangci/golangci-lint:latest \
        golangci-lint run \
            -c .golangci.yml \
	> ./golangci-lint/report-unformatted.json

.PHONY: _golangci-lint-format-report
_golangci-lint-format-report: _golangci-lint-run
	cat ./golangci-lint/report-unformatted.json | jq > ./golangci-lint/report.json

.PHONY: _golangci-lint-rm-unformatted-report
_golangci-lint-rm-unformatted-report: _golangci-lint-format-report
	rm ./golangci-lint/report-unformatted.json

.PHONY: golangci-lint-clean
golangci-lint-clean:
	sudo rm -rf ./golangci-lint

.PHONY: build
build: _create_build_dir
	go build -o ./build/gopher ./cmd/gophermart
	chmod +x ./build/gopher

.PHONY: _create_build_dir
_create_build_dir:
	mkdir -p ./build

.PHONY: ggen
ggen:
	protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative proto/pass.proto

.PHONY: start-server
start-server:
	go build -ldflags "-X main.configFilePath=$(CONFIG_FILE) -X main.masterKey=$(MASTER_KEY)" -o build/temp_server cmd/server/main.go
	-./build/temp_server

.PHONY: bc
bc:
	go build -o build/passkeep cmd/client/main.go

.PHONY: gen clean server client test cert
cert:
	cd cert; ./gen.sh; cd ..

.PHONY: genmock
genmock:
	mockgen -source internal/client/service/passkeeper/service.go -destination internal/client/service/passkeeper/mocks/service.go -package passkeeper_mock
	mockgen -source internal/client/command/command.go -destination internal/client/command/mocks/command.go -package command_mock
	mockgen -source internal/server/handler/grpc/v1/handler.go -destination internal/server/handler/grpc/v1/mocks/handler.go -package v1_mock
	mockgen -source internal/server/service/auth/service.go -destination internal/server/service/auth/mocks/service.go -package auth_mock
	mockgen -source internal/server/service/binary/service.go -destination internal/server/service/binary/mocks/service.go -package binary_mock
	mockgen -source internal/server/service/creditcard/service.go -destination internal/server/service/creditcard/mocks/service.go -package creditcard_mock
	mockgen -source internal/server/service/generaldata/service.go -destination internal/server/service/generaldata/mocks/service.go -package generaldata_mock
	mockgen -source internal/server/service/keyring/keyring.go -destination internal/server/service/keyring/mocks/keyring.go -package keyring_mock
	mockgen -source internal/server/service/loginpass/service.go -destination internal/server/service/loginpass/mocks/service.go -package loginpass_mock
	mockgen -source internal/server/service/securedata/service.go -destination internal/server/service/securedata/mocks/service.go -package data_mock
	mockgen -source internal/server/service/text/service.go -destination internal/server/service/text/mocks/service.go -package text_mock


