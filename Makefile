TAG ?= 0.3

NAME ?= nvindex

NODE_COUNT ?= 1
# GPU count is 0 by default to allow smoke tests to run
GPU_COUNT ?= 0

# Convenience makefiles.
include gcloud.Makefile
include var.Makefile
include crd.Makefile

NVINDEX_SRC_IMAGE ?= "gcr.io/nv-schlumberger/nvindex-tape-cloud"
APP_DEPLOYER_IMAGE ?= $(REGISTRY)/marketplace/nvindex/deployer:$(TAG)

APP_PARAMETERS ?= { \
  "name": "$(NAME)", \
  "namespace": "$(NAMESPACE)", \
  "imageNvindex": "$(REGISTRY)/marketplace/nvindex:$(TAG)", \
  "nodeCount": $(NODE_COUNT), \
  "gpuCount": $(GPU_COUNT) \
}

TESTER_IMAGE ?= $(REGISTRY)/marketplace/nvindex/tester:$(TAG)
APP_TEST_PARAMETERS ?= {}

# app.Makefile provides the main targets for installing the
# application.
# It requires several APP_* variables defined above, and thus
# must be included after.
include app.Makefile


# Extend the target as defined in app.Makefile to
# include real dependencies.
app/build:: .build/nvindex/deployer \
            .build/nvindex/tester \
            .build/nvindex/nvindex


.build/nvindex: | .build
	mkdir -p "$@"

.build/nvindex/deployer: .build/var/APP_DEPLOYER_IMAGE \
                         .build/var/MARKETPLACE_TOOLS_TAG \
                         .build/var/REGISTRY \
                         .build/var/TAG \
                         deployer/* \
                         chart/* \
                         schema.yaml \
                         | .build/nvindex
	$(call print_target, $@)
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)/marketplace/nvindex" \
	    --build-arg TAG="$(TAG)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"


# Build NVIDIA IndeX with some extras for GCP
# - build-in gs:// io access plugin
.build/nvindex/nvindex: .build/var/REGISTRY \
                        .build/var/TAG \
                        | .build/nvindex
	$(call print_target, $@)
	docker pull "$(NVINDEX_SRC_IMAGE)"
	docker tag "$(NVINDEX_SRC_IMAGE)" "$(REGISTRY)/marketplace/nvindex:$(TAG)"
	docker push "$(REGISTRY)/marketplace/nvindex:$(TAG)"
	@touch "$@"

.build/nvindex/nginx: .build/var/REGISTRY \
                      .build/var/TAG \
                      | .build/nginx
	$(call print_target, $@)
	docker pull nginx
	docker build -t "$(REGISTRY)/marketplace/nvindex/nginx:$(TAG)" -f nginx/Dockerfile .
	docker push "$(REGISTRY)/marketplace/nvindex/nginx:$(TAG)"
	@touch "$@"

.build/nvindex/tester: .build/var/TESTER_IMAGE \
                          $(shell find apptest -type f) \
                          | .build/nvindex
	$(call print_target,$@)
	cd apptest/tester \
	    && docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
	@touch "$@"
