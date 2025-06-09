#!/bin/bash

# Development helper script for Firestore ODM
# This script provides common development tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Firestore ODM Development Helper${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if melos is installed
check_melos() {
    if ! command -v melos &> /dev/null; then
        print_error "Melos is not installed globally"
        print_info "Installing melos..."
        dart pub global activate melos
        print_success "Melos installed successfully"
    else
        print_success "Melos is available"
    fi
}

# Bootstrap the workspace
bootstrap() {
    print_info "Bootstrapping workspace..."
    melos bootstrap
    print_success "Workspace bootstrapped"
}

# Run all quality checks
check_all() {
    print_info "Running all quality checks..."
    
    print_info "Checking code format..."
    melos run format:check
    print_success "Code formatting is correct"
    
    print_info "Running static analysis..."
    melos run analyze
    print_success "Static analysis passed"
    
    print_info "Running all tests..."
    melos run test:all
    print_success "All tests passed"
    
    print_success "All quality checks passed! 🎉"
}

# Fix common issues
fix_issues() {
    print_info "Fixing common issues..."
    
    print_info "Formatting code..."
    melos run format
    
    print_info "Applying automated fixes..."
    melos run analyze:fix
    
    print_success "Issues fixed"
}

# Clean and reset
clean_all() {
    print_info "Cleaning workspace..."
    melos run clean
    print_success "Workspace cleaned"
}

# Run example
run_example() {
    print_info "Building example..."
    melos run build:example
    print_success "Example built successfully"
}

# Preview version changes
preview_version() {
    print_info "Previewing version changes..."
    melos run version:check
}

# Show help
show_help() {
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  setup        - Initial setup (install melos, bootstrap)"
    echo "  check        - Run all quality checks"
    echo "  fix          - Fix common issues (format, analyze)"
    echo "  clean        - Clean build artifacts"
    echo "  example      - Build example project"
    echo "  version      - Preview version changes"
    echo "  publish-dry  - Dry run publishing"
    echo "  help         - Show this help message"
    echo ""
}

# Dry run publishing
publish_dry() {
    print_info "Running publish dry run..."
    melos run publish:dry-run
    print_success "Publish dry run completed"
}

# Main script logic
print_header

case "${1:-help}" in
    "setup")
        check_melos
        bootstrap
        print_success "Setup completed! Run './scripts/dev.sh check' to verify everything works."
        ;;
    "check")
        check_all
        ;;
    "fix")
        fix_issues
        ;;
    "clean")
        clean_all
        ;;
    "example")
        run_example
        ;;
    "version")
        preview_version
        ;;
    "publish-dry")
        publish_dry
        ;;
    "help"|*)
        show_help
        ;;
esac