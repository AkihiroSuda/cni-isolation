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

# arch: https://github.com/containernetworking/plugins/blob/e13bab99e54b4a34375450518d7db7a3da825e44/scripts/release.sh#L24
artifacts:
	make clean
	mkdir _artifacts
	for arch in amd64 arm arm64 ppc64le s390x mips64le; do \
		GOARCH=$$arch make ; \
		tar czvf _artifacts/cni-isolation-$${arch}.tgz --owner=0 --group=0 -C bin isolation ; \
		rm -rf bin ; \
	done

clean:
	rm -rf bin _artifacts

.PHONY: binary install uninstall bin/isolation artifacts clean
