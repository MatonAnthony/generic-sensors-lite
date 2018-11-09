#_!/bin/make -f
# -*- makefile -*-
# SPDX-License-Identifier: Apache-2.0
#{
# Copyright 2018-present Samsung Electronics France
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#}

default: all
	@echo "log: $@: $^"

project?=generic-sensors-lite
tmp_dir ?= tmp
runtime ?= node
export runtime
eslint ?= node_modules/eslint/bin/eslint.js
srcs_dir ?= .
srcs ?= $(wildcard ${project}.js */*.js | sort | uniq)
run_args ?=
run_timeout ?= 10
main_src ?= example.js
NODE_PATH := .:${NODE_PATH}
export NODE_PATH

IOTJS_EXTRA_MODULE_PATH=${CURDIR}/iotjs_modules/iotjs-async/iotjs
export IOTJS_EXTRA_MODULE_PATH

bh1750_url?=https://github.com/miroRucka/bh1750
iotjs-async_url?=https://github.com/rzr/iotjs-async
bmp085-sensor_url?=https://github.com/tizenteam/bmp085-sensor

help:
	@echo "## Usage: "

all: build
	@echo "log: $@: $^"

setup/%:
	${@F}

node_modules: package.json
	npm install

package-lock.json: package.json
	rm -fv "$@"
	npm install
	ls "$@"

setup/node: node_modules
	@echo "NODE_PATH=$${NODE_PATH}"
	node --version
	npm --version

setup: setup/${runtime}
	@echo "log: $@: $^"

build/%: setup
	@echo "log: $@: $^"

build/node: setup node_modules lint
	@echo "log: $@: $^"

build: build/${runtime}
	@echo "log: $@: $^"

run/%: ${main_src} build
	${@F} $< ${run_args}

run/npm: ${main_src} setup
	npm start

run: run/${runtime}
	@echo "log: $@: $^"

clean:
	rm -rf ${tmp_dir}

cleanall: clean
	rm -f *~

distclean: cleanall
	rm -rf node_modules

test/npm: package.json
	npm test

test: test/${runtime}

start: run
	@echo "log: $@: $^"

check/%: ${srcs}
	${MAKE} setup
	@echo "log: SHELL=$${SHELL}"
	status=0 ; \
 for src in $^; do \
 echo "log: check: $${src}: ($@)" ; \
 ${@F} $${src} \
 && echo "log: check: $${src}: OK" \
 || status=1 ; \
 done ; \
	exit $${status}

check/npm:
	npm run lint

check: check/${runtime}
	@echo "log: $@: $^"

eslint/setup: node_modules
	ls ${eslint} || npm install eslint-plugin-node eslint
	${eslint} --version

${eslint}:
	ls $@ || make eslint/setup
	touch $@

.eslintrc.js: ${eslint}
	ls $@ || $< --init

eslint: ${eslint}
	$< --fix . ||:
	$< --fix .

lint/%: eslint
	@echo "log: $@: $^"

lint: lint/${runtime}
	@echo "log: $@: $^"

iotjs_modules: iotjs_modules/bmp085-sensor iotjs_modules/bh1750
	ls $@

iotjs_modules/%:
	-mkdir -p ${@D}
	git clone --recursive --depth 1 https://github.com/TizenTeam/${@F} $@

iotjs_modules/bh1750:
	-mkdir -p ${@D}
	git clone --recursive --depth 1 ${bh1750_url} $@

iotjs_modules/iotjs-async:
	-mkdir -p ${@D}
	git clone --recursive --depth 1 ${iotjs-async_url} $@

iotjs_modules/bmp085-sensor: iotjs_modules/iotjs-async
	-mkdir -p ${@D}
	git clone --recursive --depth 1 ${bmp085-sensor_url} $@

setup/iotjs: ${runtime}_modules
	${@F} -h ||:
