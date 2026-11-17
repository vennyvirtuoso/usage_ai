.PHONY: all build run test clean install

all: build

build:
	./build.sh

run:
	./run.sh

test:
	mkdir -p /tmp/swift-tmp /tmp/swift-cache
	TMPDIR=/tmp/swift-tmp swiftc -module-cache-path /tmp/swift-cache \
		Sources/UsageAI/Models/TokenRecord.swift \
		Sources/UsageAI/Models/AppSettings.swift \
		Sources/UsageAI/Services/PricingCalculator.swift \
		Sources/UsageAI/Services/AntigravityScanner.swift \
		Sources/UsageAI/Services/ClaudeScanner.swift \
		Sources/UsageAI/Services/AntigravityLiveService.swift \
		Sources/UsageAI/Services/ClaudeLiveService.swift \
		Tests/RunTests.swift \
		-o /tmp/run_tests && /tmp/run_tests

install:
	./install.sh

clean:
	rm -rf build /tmp/swift-tmp /tmp/swift-cache /tmp/run_tests
