NAME ?= nvindex
APP_ID ?= marketplace/nvindex

# Track should be the major.minor of RELEASE.
TRACK ?= 2.2
RELEASE ?= 2.2.1

NODE_COUNT ?= 1
# GPU count is 0 by default to allow smoke tests to run
GPU_COUNT ?= 0

GCS_URL ?= gs://nvindex-data-samples
REGISTRY ?= gcr.io/nv-schlumberger

# Convenience makefiles.
include gcloud.Makefile
include var.Makefile
include crd.Makefile

NVINDEX_SRC_IMAGE ?= "gcr.io/nv-schlumberger/nvindex-tape-cloud:$(TRACK)"

APP_DEPLOYER_IMAGE ?= $(REGISTRY)/$(APP_ID)/deployer:$(RELEASE)
APP_DEPLOYER_IMAGE_TRACK_TAG ?= $(REGISTRY)/$(APP_ID)/deployer:$(TRACK)
APP_GCS_PATH ?= $(GCS_URL)/$(APP_ID)/$(TRACK)

APP_PARAMETERS ?= { \
  "name": "$(NAME)", \
  "namespace": "$(NAMESPACE)", \
  "nodeCount": $(NODE_COUNT), \
  "gpuCount": $(GPU_COUNT) \
}

TESTER_IMAGE ?= $(REGISTRY)/$(APP_ID)/tester:$(RELEASE)
APP_TEST_PARAMETERS ?= {}

# app.Makefile provides the main targets for installing the
# application.
# It requires several APP_* variables defined above, and thus
# must be included after.
# Use schema version 2 app Makefile.
include app_v2.Makefile

# Extend the target as defined in app.Makefile to
# include real dependencies.
app/build:: .build/nvindex/deployer \
            .build/nvindex/tester \
			.build/nvindex/nginx \
			.build/nvindex/gcloudsdk \
            .build/nvindex/nvindex


.build/nvindex: | .build
	mkdir -p "$@"

.build/nvindex/deployer: .build/var/APP_DEPLOYER_IMAGE \
                         .build/var/MARKETPLACE_TOOLS_TAG \
                         .build/var/REGISTRY \
                         .build/var/TRACK \
                         .build/var/RELEASE \
                         deployer/* \
                         chart/* \
                         schema.yaml \
                         | .build/nvindex
	$(call print_target, $@)
	docker build \
	    --build-arg RELEASE="$(RELEASE)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker tag "$(APP_DEPLOYER_IMAGE)" "$(APP_DEPLOYER_IMAGE_TRACK_TAG)"
	docker push "$(APP_DEPLOYER_IMAGE_TRACK_TAG)"
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"


# Build NVIDIA IndeX with some extras for GCP
# - build-in gs:// io access plugin
.build/nvindex/nvindex: .build/var/REGISTRY \
                        .build/var/TRACK \
                        .build/var/RELEASE \
                        | .build/nvindex
	$(call print_target, $@)
	docker pull "$(NVINDEX_SRC_IMAGE)"
	docker tag "$(NVINDEX_SRC_IMAGE)" "$(REGISTRY)/$(APP_ID):$(TRACK)"
	docker tag "$(REGISTRY)/$(APP_ID):$(TRACK)" "$(REGISTRY)/$(APP_ID):$(RELEASE)"
	docker push "$(REGISTRY)/$(APP_ID):$(TRACK)"
	docker push "$(REGISTRY)/$(APP_ID):$(RELEASE)"
	@touch "$@"

.build/nvindex/tester: .build/var/TESTER_IMAGE \
                       $(shell find apptest -type f) \
                       | .build/nvindex
	$(call print_target,$@)
	cd apptest/tester \
	    && docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
	@touch "$@"

# Dependent images: nginx
.build/nvindex/nginx: .build/var/REGISTRY \
                      .build/var/TRACK \
                      .build/var/RELEASE \
                      | .build/nvindex
	$(call print_target, $@)
	docker pull mirror.gcr.io/library/nginx
	docker tag mirror.gcr.io/library/nginx $(REGISTRY)/$(APP_ID)/nginx:$(TRACK)
	docker tag mirror.gcr.io/library/nginx $(REGISTRY)/$(APP_ID)/nginx:$(RELEASE)
	docker push $(REGISTRY)/$(APP_ID)/nginx:$(TRACK)
	docker push $(REGISTRY)/$(APP_ID)/nginx:$(RELEASE)
	@touch "$@"

# Dependent images: Google Cloud SDK
.build/nvindex/gcloudsdk : .build/var/REGISTRY \
                           .build/var/TRACK \
                           .build/var/RELEASE \
                           | .build/nvindex
	$(call print_target, $@)
	docker pull gcr.io/google.com/cloudsdktool/cloud-sdk:alpine
	docker tag gcr.io/google.com/cloudsdktool/cloud-sdk:alpine $(REGISTRY)/$(APP_ID)/gcloudsdk:$(TRACK)
	docker tag gcr.io/google.com/cloudsdktool/cloud-sdk:alpine $(REGISTRY)/$(APP_ID)/gcloudsdk:$(RELEASE)
	docker push $(REGISTRY)/$(APP_ID)/gcloudsdk:$(TRACK)
	docker push $(REGISTRY)/$(APP_ID)/gcloudsdk:$(RELEASE)
	@touch "$@"
