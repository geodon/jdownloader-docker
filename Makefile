.PHONY: build run logs clean stop restart

# Load environment variables from .env if it exists
-include .env

# Default values
IMAGE_NAME ?= jdownloader
CONTAINER_NAME ?= jdtest
VOLUME_DIR = .local

build:
	docker build --build-arg UID=$$(id -u) --build-arg GID=$$(id -g) -t $(IMAGE_NAME) .

restart:
	docker restart $(CONTAINER_NAME)

run: build stop
	@mkdir -p $(VOLUME_DIR)/jdownloader $(VOLUME_DIR)/downloads
	docker run -d --name $(CONTAINER_NAME) \
		--restart unless-stopped \
		-e MYJD_EMAIL=$(MYJD_EMAIL) \
		-e MYJD_PASSWORD=$(MYJD_PASSWORD) \
		-e MYJD_DEVICENAME=$(MYJD_DEVICENAME) \
		-v $$(pwd)/$(VOLUME_DIR)/jdownloader:/JDownloader \
		-v $$(pwd)/$(VOLUME_DIR)/downloads:/Downloads \
		$(IMAGE_NAME)
	@echo "Container $(CONTAINER_NAME) started"

logs:
	@echo "Following logs for $(CONTAINER_NAME) (Ctrl+C to stop)..."
	@while docker ps -a --format '{{.Names}}' | grep -q '^$(CONTAINER_NAME)$$'; do \
		docker logs -f $(CONTAINER_NAME) 2>&1 || sleep 1; \
	done

stop:
	-docker stop $(CONTAINER_NAME)
	-docker rm $(CONTAINER_NAME)

clean: stop
	-docker rmi $(IMAGE_NAME)
	rm -rf $(VOLUME_DIR)
	@echo "Cleaned up image, volumes and container"
