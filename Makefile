# Tennis Score — сборка, тесты, запуск в симуляторе, скриншоты.

XCODEGEN := $(shell command -v xcodegen 2>/dev/null || echo ./tools/xcodegen/bin/xcodegen)
DERIVED := DerivedData
APP := $(DERIVED)/Build/Products/Debug-iphonesimulator/TennisScore.app
BUNDLE_ID := com.efremov.tennisscore
DEMOS := home newmatch match tiebreak 105 victory history settings auth paywall

# Самый новый доступный iPhone (не хардкодим имя).
UDID = $(shell python3 scripts/pick_sim.py)

.PHONY: setup test typecheck build run shots icon clean

setup:
	@if ! command -v xcodegen >/dev/null && [ ! -x ./tools/xcodegen/bin/xcodegen ]; then \
		if command -v brew >/dev/null; then brew install xcodegen; \
		else \
			echo "Скачиваю xcodegen с GitHub…"; \
			mkdir -p tools && cd tools && \
			curl -sL -o xcodegen.zip https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip && \
			unzip -qo xcodegen.zip; \
		fi \
	fi
	$(XCODEGEN) generate

icon:
	python3 scripts/make_icon.py

test:
	cd TennisEngine && swift test

# Быстрая проверка компиляции UI без симулятора.
typecheck:
	SDKPATH=$$(xcrun --sdk iphonesimulator --show-sdk-path) && \
	swift build --triple arm64-apple-ios17.0-simulator \
		-Xswiftc -sdk -Xswiftc "$$SDKPATH" -Xcc -isysroot -Xcc "$$SDKPATH"

build: setup
	xcodebuild -project TennisScore.xcodeproj -scheme TennisScore \
		-destination 'id=$(UDID)' -derivedDataPath $(DERIVED) \
		-quiet build

boot:
	@xcrun simctl bootstatus $(UDID) -b >/dev/null 2>&1 || xcrun simctl boot $(UDID) || true
	@open -a Simulator
	@xcrun simctl bootstatus $(UDID) -b

run: build boot
	xcrun simctl install $(UDID) "$(APP)"
	xcrun simctl launch $(UDID) $(BUNDLE_ID)

# Скриншоты всех demo-экранов: light + dark.
shots: build boot
	@mkdir -p screenshots
	@xcrun simctl install $(UDID) "$(APP)"
	@xcrun simctl status_bar $(UDID) override --time "9:41" --batteryLevel 100 --wifiBars 3 --cellularBars 4 2>/dev/null || true
	@for mode in light dark; do \
		xcrun simctl ui $(UDID) appearance $$mode; \
		for demo in $(DEMOS); do \
			name=$$demo; [ "$$mode" = "dark" ] && name=$${demo}_dark; \
			echo "▸ $$name"; \
			xcrun simctl terminate $(UDID) $(BUNDLE_ID) 2>/dev/null || true; \
			xcrun simctl launch $(UDID) $(BUNDLE_ID) --demo $$demo >/dev/null; \
			sleep 2.5; \
			xcrun simctl io $(UDID) screenshot screenshots/$$name.png >/dev/null; \
		done; \
	done
	@xcrun simctl ui $(UDID) appearance light
	@echo "Скриншоты: ./screenshots"

clean:
	rm -rf $(DERIVED) TennisScore.xcodeproj screenshots

print-udid:
	@echo "UDID=$(UDID)"
