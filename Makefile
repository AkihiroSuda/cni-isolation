.DEFAULT_GOAL := binary

GO := go

GO_BUILD := GO111MODULE=on CGO_ENABLED=0 $(GO) build -ldflags="-s -w"

CNI_PATH := /opt/cni/bin

binary: bin/isolation

install:
	mkdir -p $(CNI_PATH)
	cp -f bin/isolation $(CNI_PATH)

uninstall:
	rm -f $(CNI_PATH)/bin

bin/isolation:
	mkdir -p bin
	$(GO_BUILD) -o bin/isolation ./plugins/meta/isolation

clean:
	rm -rf bin

.PHONY: binary install uninstall bin/isolation clean
