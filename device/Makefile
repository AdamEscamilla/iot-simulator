OPENSSL_DIR ?= /usr/local/lib
CC=gcc # gcc || clang
CCOPTIONS=-std=c11 -Werror -Wall -Wextra -pedantic -Wstrict-overflow -fno-strict-aliasing -fdiagnostics-show-option
SSLPATH=-L$(OPENSSL_DIR)

all: mqtt_client.c
	$(CC) $(CCOPTIONS) $(SSLPATH) mqtt_client.c $(BUILDARGS) -ljwt -lcrypto -lssl -lpaho-mqtt3cs -ljansson -o mqtt_client

tidy:
	@for src in $(shell find . -name '*.c') ; do \
		echo "Running tidy on $$src..." ; \
		clang-tidy "$$src" -- $(CCOPTIONS); \
	done
	@echo "Done"
