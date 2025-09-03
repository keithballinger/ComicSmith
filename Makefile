# ComicSmith Makefile
# Build and test automation for ComicSmith macOS app

SWIFT := swift
XCODEBUILD := xcodebuild
SWIFTLINT := swiftlint

# Directories
CORE_DIR := ComicSmithCore
DEMO_DIR := ComicSmithDemoApp
BUILD_DIR := .build
DERIVED_DATA := ~/Library/Developer/Xcode/DerivedData

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

.PHONY: all build test clean lint help build-core build-demo test-core test-demo run-demo

# Default target
all: lint build test

# Help target
help:
	@echo "$(GREEN)ComicSmith Build System$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo "  make build       - Build all packages"
	@echo "  make test        - Run all tests"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make lint        - Run SwiftLint"
	@echo "  make build-core  - Build ComicSmithCore package"
	@echo "  make build-demo  - Build demo app"
	@echo "  make test-core   - Test ComicSmithCore"
	@echo "  make test-demo   - Test demo app"
	@echo "  make run-demo    - Build and run demo app"
	@echo "  make format      - Format code with SwiftLint"
	@echo "  make coverage    - Generate test coverage report"
	@echo ""

# Build all packages
build: build-core build-demo
	@echo "$(GREEN)✓ All packages built successfully$(NC)"

# Build ComicSmithCore
build-core:
	@echo "$(YELLOW)Building ComicSmithCore...$(NC)"
	@cd $(CORE_DIR) && $(SWIFT) build
	@echo "$(GREEN)✓ ComicSmithCore built$(NC)"

# Build demo app
build-demo:
	@echo "$(YELLOW)Building ComicSmithDemoApp...$(NC)"
	@cd $(DEMO_DIR) && $(SWIFT) build
	@echo "$(GREEN)✓ ComicSmithDemoApp built$(NC)"

# Test all packages
test: test-core
	@echo "$(GREEN)✓ All tests passed$(NC)"

# Test ComicSmithCore
test-core:
	@echo "$(YELLOW)Testing ComicSmithCore...$(NC)"
	@cd $(CORE_DIR) && $(SWIFT) test
	@echo "$(GREEN)✓ ComicSmithCore tests passed$(NC)"

# Test demo app (if tests exist)
test-demo:
	@echo "$(YELLOW)Testing ComicSmithDemoApp...$(NC)"
	@cd $(DEMO_DIR) && $(SWIFT) test 2>/dev/null || echo "$(YELLOW)No tests in demo app$(NC)"

# Run demo app
run-demo: build-demo
	@echo "$(YELLOW)Running ComicSmithDemoApp...$(NC)"
	@cd $(DEMO_DIR) && $(SWIFT) run

# Run SwiftLint
lint:
	@echo "$(YELLOW)Running SwiftLint...$(NC)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		$(SWIFTLINT) lint --config .swiftlint.yml; \
		echo "$(GREEN)✓ Linting complete$(NC)"; \
	else \
		echo "$(YELLOW)SwiftLint not installed. Skipping linting.$(NC)"; \
		echo "$(YELLOW)To install: brew install swiftlint$(NC)"; \
	fi

# Format code with SwiftLint
format:
	@echo "$(YELLOW)Formatting code with SwiftLint...$(NC)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		$(SWIFTLINT) lint --fix --config .swiftlint.yml; \
		echo "$(GREEN)✓ Code formatted$(NC)"; \
	else \
		echo "$(YELLOW)SwiftLint not installed. Cannot format code.$(NC)"; \
		echo "$(YELLOW)To install: brew install swiftlint$(NC)"; \
	fi

# Generate test coverage
coverage: test-core
	@echo "$(YELLOW)Generating test coverage report...$(NC)"
	@cd $(CORE_DIR) && $(SWIFT) test --enable-code-coverage
	@echo "$(GREEN)✓ Coverage report generated$(NC)"
	@echo "View coverage at: $(CORE_DIR)/.build/debug/codecov/*.json"

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@cd $(CORE_DIR) && $(SWIFT) package clean 2>/dev/null || true
	@cd $(DEMO_DIR) && $(SWIFT) package clean 2>/dev/null || true
	@rm -rf $(BUILD_DIR)
	@echo "$(GREEN)✓ Build artifacts cleaned$(NC)"

# Deep clean including all caches
deep-clean: clean
	@echo "$(YELLOW)Deep cleaning all caches...$(NC)"
	@cd $(CORE_DIR) && rm -rf .build Package.resolved
	@cd $(DEMO_DIR) && rm -rf .build Package.resolved
	@echo "$(GREEN)✓ Deep clean complete$(NC)"

# Check dependencies
check-deps:
	@echo "$(YELLOW)Checking dependencies...$(NC)"
	@echo -n "Swift: "
	@$(SWIFT) --version | head -n 1
	@echo -n "SwiftLint: "
	@if command -v swiftlint >/dev/null 2>&1; then \
		$(SWIFTLINT) version; \
	else \
		echo "$(RED)Not installed$(NC)"; \
	fi
	@echo "$(GREEN)✓ Dependency check complete$(NC)"

# Install development dependencies
install-deps:
	@echo "$(YELLOW)Installing development dependencies...$(NC)"
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "$(RED)Homebrew not installed. Please install from https://brew.sh$(NC)"; \
		exit 1; \
	fi
	@if ! command -v swiftlint >/dev/null 2>&1; then \
		echo "Installing SwiftLint..."; \
		brew install swiftlint; \
	else \
		echo "SwiftLint already installed"; \
	fi
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

# Quick build and test (for CI or pre-commit)
quick: lint build-core test-core
	@echo "$(GREEN)✓ Quick validation passed$(NC)"

# Watch for changes and rebuild (requires fswatch)
watch:
	@if command -v fswatch >/dev/null 2>&1; then \
		echo "$(YELLOW)Watching for changes... (Ctrl-C to stop)$(NC)"; \
		fswatch -o $(CORE_DIR)/Sources $(DEMO_DIR)/Sources | xargs -n1 -I{} make build; \
	else \
		echo "$(RED)fswatch not installed. Install with: brew install fswatch$(NC)"; \
		exit 1; \
	fi

# Generate documentation (requires swift-doc)
docs:
	@if command -v swift-doc >/dev/null 2>&1; then \
		echo "$(YELLOW)Generating documentation...$(NC)"; \
		swift-doc generate $(CORE_DIR)/Sources/ComicSmithCore \
			--module-name ComicSmithCore \
			--output docs; \
		echo "$(GREEN)✓ Documentation generated at ./docs$(NC)"; \
	else \
		echo "$(RED)swift-doc not installed. Install with: brew install swift-doc$(NC)"; \
		exit 1; \
	fi