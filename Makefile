VERSION ?= 1

REPO = dakku/drupal_tests
NAME = drupal_tests

.PHONY: build shell run start stop logs clean release

build:
	docker build -t $(REPO):$(VERSION) ./

shell:
	docker run --rm --name $(NAME)-$(VERSION) -i -t $(ENV) $(REPO):$(VERSION) /bin/bash

run:
	docker run --rm --name $(NAME) $(ENV) $(REPO):$(VERSION) $(CMD)

start:
	docker run -d --name $(NAME) $(ENV) $(REPO):$(VERSION)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	docker rm -f $(NAME)

tag:
	docker tag $(REPO):$(VERSION) $(REPO):$(VERSION)

push: tag
	docker push $(REPO)

release: build
	make push -e VERSION=$(VERSION)

default: build
