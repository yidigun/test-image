#
# Makefile for Docker multiplatform building
#
# Requires:    bash, docker-cli, docker-buildx-plugin, regctl
#

# Image info
PUBLIC_REPO  = docker.io
LOCAL_REPO   = anas:5000
IMAGE_NAME   = yidigun/test-image
IMAGE_TAG    = 3.0.1
BUILDER_IMAGE= $(LOCAL_REPO)/builder/test-image:$(IMAGE_TAG)

# Release
# For publishing to public repo, use `make PUSH_PUBLIC=yes SET_LATEST=yes`.
#PUSH_PUBLIC  = yes
#SET_LATEST   = yes
#RM_OS_TAGS   = yes

# Develop
# Wheather to push to public repo
PUSH_PUBLIC  = no
# Whether to set 'latest' tag also
SET_LATEST   = no
# Wheather to remove OS specific tags after merging
RM_OS_TAGS   = yes

# Build hosts
CONTEXT         =
BUILDER         = crossbuilder
CONTEXT_WINDOWS = vwin
define BUILDER_CONFIG
anas ssh://anas linux/arm64,linux/arm/v7,linux/arm/v6
xvms ssh://xvms linux/amd64,linux/amd64/v2,linux/riscv64,linux/ppc64,linux/ppc64le,linux/s390x, linux/386, linux/loong64
endef
export BUILDER_CONFIG

# Supported platforms
LINUX_ARCHS   = linux/amd64,linux/arm64
TARGETS       =	build/linux-$(IMAGE_TAG) \
                build/windows-ltsc2022-$(IMAGE_TAG) \
                build/windows-ltsc2025-$(IMAGE_TAG)

# Apply local environemnt
-include local.mk

# Specify all the files for tracking changes
LINUX_FILES   = main.go go.mod
WINDOWS_FILES = $(LINUX_FILES)

.PHONY: merge clean create-$(BUILDER) bin clean-bin builder

merge: build/merge-local-$(IMAGE_TAG) build/merge-public-$(IMAGE_TAG)

clean:
	@echo "This action does not remove already pushed images."
	rm -rf $(TARGETS) build/builder-$(IMAGE_TAG)

create-$(BUILDER):
	printf '%s\n' "$$BUILDER_CONFIG" | \
	LOCAL_REPO="$(LOCAL_REPO)" \
	CONTEXT="$(CONTEXT)" \
	Makefile.bin/create-builder.sh $(BUILDER)

build/merge-public-$(IMAGE_TAG): $(TARGETS)
	if [ "$(PUSH_PUBLIC)" = "yes" ]; then \
	    temp_tags=; \
	    for t in $(TARGETS); do \
	        temp_tags="$$temp_tags $$(basename $$t)"; \
	    done; \
	    REPO="$(PUBLIC_REPO)" \
	    IMAGE_NAME="$(IMAGE_NAME)" \
	    IMAGE_TAG="$(IMAGE_TAG)" \
	    SET_LATEST="$(SET_LATEST)" \
	    RM_OS_TAGS="$(RM_OS_TAGS)" \
	    CONTEXT="$(CONTEXT)" \
	    BUILDER="$(BUILDER)" \
	    LINUX_ARCHS="$(LINUX_ARCHS)" \
	    Makefile.bin/merge-tags.sh $$temp_tags && \
	    mkdir -p build && touch $@; \
	else \
	    mkdir -p build && touch $@; \
	fi

build/merge-local-$(IMAGE_TAG): $(TARGETS)
	temp_tags=; \
	for t in $(TARGETS); do \
	    temp_tags="$$temp_tags $$(basename $$t)"; \
	done; \
	REPO="$(LOCAL_REPO)" \
	IMAGE_NAME="$(IMAGE_NAME)" \
	IMAGE_TAG="$(IMAGE_TAG)" \
	SET_LATEST="$(SET_LATEST)" \
	RM_OS_TAGS="$(RM_OS_TAGS)" \
	CONTEXT="$(CONTEXT)" \
	BUILDER="$(BUILDER)" \
	LINUX_ARCHS="$(LINUX_ARCHS)" \
	Makefile.bin/merge-tags.sh $$temp_tags && \
	mkdir -p build && touch $@

build/linux-$(IMAGE_TAG): Dockerfile.linux $(LINUX_FILES)
	PUBLIC_REPO="$(PUBLIC_REPO)" \
	LOCAL_REPO="$(LOCAL_REPO)" \
	IMAGE_NAME="$(IMAGE_NAME)" \
	IMAGE_TAG="$$(basename $@)" \
	PUSH_PUBLIC="$(PUSH_PUBLIC)" \
	SET_LATEST="$(SET_LATEST)" \
	CONTEXT="$(CONTEXT)" \
	BUILDER="$(BUILDER)" \
	BASE_IMAGE=alpine \
	BASE_VERSION=3.22.2 \
	Makefile.bin/run-buildx.sh \
	  -f Dockerfile.linux \
	  --platform="$(LINUX_ARCHS)" && \
	mkdir -p build && touch $@

build/builder-$(IMAGE_TAG): Dockerfile.builder $(WINDOWS_FILES)
	docker --context=$(CONTEXT_WINDOWS) build \
	--platform=windows/amd64 \
	-t $(BUILDER_IMAGE) \
	-f Dockerfile.builder . && \
	mkdir -p build && touch $@

build/windows-ltsc2025-$(IMAGE_TAG): Dockerfile.windows $(WINDOWS_FILES) build/builder-$(IMAGE_TAG)
	PUBLIC_REPO="$(PUBLIC_REPO)" \
	LOCAL_REPO="$(LOCAL_REPO)" \
	IMAGE_NAME="$(IMAGE_NAME)" \
	IMAGE_TAG="$$(basename $@)" \
	PUSH_PUBLIC="$(PUSH_PUBLIC)" \
	SET_LATEST="$(SET_LATEST)" \
	CONTEXT="$(CONTEXT_WINDOWS)" \
	BASE_IMAGE=nanoserver \
	BASE_VERSION=ltsc2025 \
	Makefile.bin/run-build.sh \
	  --build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
	  -f Dockerfile.windows && \
	mkdir -p build && touch $@

build/windows-ltsc2022-$(IMAGE_TAG): Dockerfile.windows $(WINDOWS_FILES) build/builder-$(IMAGE_TAG) \
			build/windows-ltsc2025-$(IMAGE_TAG) # for sequential build on single host
	PUBLIC_REPO="$(PUBLIC_REPO)" \
	LOCAL_REPO="$(LOCAL_REPO)" \
	IMAGE_NAME="$(IMAGE_NAME)" \
	IMAGE_TAG="$$(basename $@)" \
	PUSH_PUBLIC="$(PUSH_PUBLIC)" \
	SET_LATEST="$(SET_LATEST)" \
	CONTEXT="$(CONTEXT_WINDOWS)" \
	BASE_IMAGE=nanoserver \
	BASE_VERSION=ltsc2022 \
	Makefile.bin/run-build.sh \
	  --build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
	  -f Dockerfile.windows && \
	mkdir -p build && touch $@

# for local build and tests

GO_SRC     = main.go go.mod
GO_TARGETS = build/linux/amd64/test-image \
			build/linux/arm64/test-image \
			build/windows/amd64/test-image.exe
GOFLAGS    = -a -ldflags "-s -w"

bin: $(GO_TARGETS)
clean-bin:
	rm -rf build/linux build/windows

build/linux/arm64 build/linux/amd64 build/windows/amd64:
	mkdir -p $@

build/linux/arm64/test-image: $(GO_SRC) | build/linux/arm64
	GOOS=linux GOARCH=arm64 go build $(GOFLAGS) -o $@
build/linux/amd64/test-image: $(GO_SRC) | build/linux/amd64
	GOOS=linux GOARCH=amd64 go build $(GOFLAGS) -o $@
build/windows/amd64/test-image.exe: $(GO_SRC) | build/windows/amd64
	GOOS=windows GOARCH=amd64 go build $(GOFLAGS) -o $@

