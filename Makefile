REPOSITORY := erwinnttdata
NAME := activemq
VERSION ?= 5.14.3_007

build: _build ##@targets Builds the docker image.
.PHONY: build

rebuild: _rebuild ##@targets Builds the docker image anew.
.PHONY: rebuild

clean: _clean ##@targets Removes the docker image.
.PHONY: clean

deploy: _deploy ##@targets Deploys the docker image to the repository.
.PHONY: deploy

include ../docker_make_utils/Makefile.help
include ../docker_make_utils/Makefile.functions
include ../docker_make_utils/Makefile.image
