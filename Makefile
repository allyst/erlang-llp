#!/usr/bin/env make -rRf

APP_NAME := llp

include ./project.mk

run: compile
	@echo "[ Run... ]"
	@$(ERL) -name llp@127.0.0.1\
			-pa ebin deps/*/ebin  ../deps/*/ebin ../*/ebin\
			-s llp_helper
			-setcookie dev -Ddebug=true