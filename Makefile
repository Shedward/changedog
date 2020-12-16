PRODUCT_NAME=changedog
PREFIX=/usr/local
BIN_PATH=$(PREFIX)/bin
BIN_PRODUCT_PATH=$(BIN_PATH)/$(PRODUCT_NAME)

build:
	swift build --disable-sandbox -c release

install: build
	mkdir -p $(BIN_PATH)
	cp -f .build/release/$(PRODUCT_NAME) $(BIN_PRODUCT_PATH)

uninsall:
	rm -rf $(BIN_PRODUCT_PATH)