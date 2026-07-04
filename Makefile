# ========================================
# FileName: Makefile
# Date: 07.03.2023
# Author: Marcos Chow Castro
# Email: mctechnology170318@gmail.com
# GitHub: https://github.com/mctechnology17
# Brief: Makefile for ZMK firmware with Docker
# Shields: corne
# Boards: nice_nano_v2
# =========================================
#                              ╔═╦═╦═╗
#                       ╔════╗ ║║║║║╔╝
#                       ║╔╗╔╗║ ║║║║║╚╗
#                       ╚╝║║╚╝ ║╠═╩╩═╝
#                         ║╠═╦═╣╚╦═╦╦═╦╗╔═╦═╦╦╗
#                         ║║╩╣═╣║║║║║╬║╚╣╬║╬║║║
#                         ╚╩═╩═╩╩╩╩═╩═╩═╩═╬╗╠╗║
#                                         ╚═╩═╝
# to update the branch
# https://hub.docker.com/r/zmkfirmware/zmk-dev-arm/tags
# https://github.com/zmkfirmware/zmk/blob/main/.devcontainer/Dockerfile
# docker pull zmkfirmware/zmk-dev-arm:3.2-branch
#
# CUSTOM BRANCH EXAMPLE:
# git clone https://github.com/petejohanson/zmk -b v3.4.0+zmk-fixes

### config
extra_modules_dir=${PWD}
extra_modules= -DZMK_EXTRA_MODULES="/boards"
config=${PWD}/config
nice_mount=/Volumes/NICENANO
zmk_image=zmkfirmware/zmk-dev-arm:3.5
nice=nice_nano_v2
urob=zmk-codebase_urob
# --name zmk-$@ is for codebase_urob, for example: zmk-codebase_urob
docker_opts= \
	--interactive \
	--tty \
	--name zmk-$@ \
	--workdir /zmk \
	--volume "${config}:/zmk-config:Z" \
	--volume "${PWD}/zmk:/zmk:Z" \
	--volume "${extra_modules_dir}:/boards:Z" \
	${zmk_image}

### name
keyboard_name_nice= '-DCONFIG_ZMK_KEYBOARD_NAME="Nice_Corne_View"'

### west
west_built_nice= \
	    west build /zmk/app \
	    --pristine --board "${nice}"

### shields
shield_corne_left= \
	    -- -DSHIELD="corne_left" -DZMK_CONFIG="/zmk-config"
shield_corne_right= \
	    -- -DSHIELD="corne_right" -DZMK_CONFIG="/zmk-config"

###  uf2
uf2_source_nice_corne_left=zmk/build/zephyr/zmk.uf2
uf2_source_nice_corne_right=zmk/build/zephyr/zmk.uf2
uf2_copy_nice_corne_left=mkdir -p firmware && cp ${uf2_source_nice_corne_left} firmware/nice_corne_left.uf2
uf2_copy_nice_corne_right=mkdir -p firmware && cp ${uf2_source_nice_corne_right} firmware/nice_corne_right.uf2
### chmod
uf2_chmod_nice_corne_left=chmod go+wrx firmware/nice_corne_left.uf2
uf2_chmod_nice_corne_right=chmod go+wrx firmware/nice_corne_right.uf2


clone_zmk_urob:
	if [ ! -d zmk ]; then git clone https://github.com/urob/zmk; fi

codebase_urob: clone_zmk_urob
	docker run --rm ${docker_opts} sh -c '\
		west init -l /zmk/app/ || true; \
		west update'

### CODEBASE_UROB START
only_nice_corne_left_view_urob: codebase_urob
	docker run --rm ${docker_opts} sh -c '\
		west init -l /zmk/app/ || true; \
		west update; \
		${west_built_nice} ${shield_corne_left} \
		${keyboard_name_nice} ${extra_modules}'
	${uf2_copy_nice_corne_left}
	${uf2_chmod_nice_corne_left}
only_nice_corne_right_view_urob: codebase_urob
	docker run --rm ${docker_opts} sh -c '\
		west init -l /zmk/app/ || true; \
		west update; \
		${west_built_nice} ${shield_corne_right} ${extra_modules}'
	${uf2_copy_nice_corne_right}
	${uf2_chmod_nice_corne_right}

only_corne_left_view_urob: only_nice_corne_left_view_urob
only_corne_right_view_urob: only_nice_corne_right_view_urob
corne_urob: only_corne_left_view_urob \
	only_corne_right_view_urob
### CODEBASE_UROB END

# Open a shell within the ZMK environment
shell:
	docker run --rm ${docker_opts} /bin/bash

# Flash the appropriate firmware to the bootloader
nice_corne_flash_left:
	@ printf "Waiting for ${nice} bootloader to appear at ${nice_mount}.."
	@ while [ ! -d ${nice_mount} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_left.uf2 ${nice_mount}

nice_corne_flash_right:
	@ printf "Waiting for ${nice} bootloader to appear at ${nice_mount}.."
	@ while [ ! -d ${nice_mount} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_right.uf2 ${nice_mount}

clean_firmware:
	find firmware/*.uf2 -type f -delete

clean_zmk:
	if [ -d zmk ]; then rm -rfv zmk; fi

clean: clean_zmk
	docker ps -aq --filter name='^zmk' | xargs -r docker container rm
	docker volume list -q --filter name='zmk' | xargs -r docker volume rm

clean_all: clean clean_firmware
	@echo "cleaning all"

# vim: set ft=make fdm=marker:
