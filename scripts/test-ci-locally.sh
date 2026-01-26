#!/usr/bin/env bash
set -euo pipefail

# Local CI Matrix Testing Script
# This script mimics the GitHub Actions CI workflow for local testing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RUN_BUILD=true
RUN_INTEGRATION=true
RUN_MATRIX=true
RUN_LINT=true
TERRAFORM_VERSIONS=("1.6.*" "1.7.*" "1.8.*")  # Default subset for faster local testing
LATTICE_IMAGE="${LATTICE_IMAGE:-ghcr.io/latticehq/lattice}"

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Local CI Matrix Testing Script - Test the Terraform provider locally with multiple Terraform versions

OPTIONS:
    --skip-build            Skip the build step
    --skip-integration      Skip integration tests
    --skip-matrix           Skip matrix tests (acceptance tests across TF versions)
    --skip-lint             Skip linting
    --only-build            Run only the build step
    --only-integration      Run only integration tests
    --only-matrix           Run only matrix tests
    --only-lint             Run only linting
    --tf-versions "1.7.* 1.8.*"  Specify Terraform versions for matrix (space-separated, quoted)
    --all-versions          Test with all Terraform versions from CI (1.0 - 1.8)
    --quick                 Quick test with only latest TF version (1.8.*)
    -h, --help              Show this help message

EXAMPLES:
    # Run full CI suite (default subset of TF versions)
    $0

    # Quick test with only latest Terraform
    $0 --quick

    # Test all Terraform versions
    $0 --all-versions

    # Test specific Terraform versions
    $0 --tf-versions "1.5.* 1.6.* 1.7.*"

    # Run only matrix tests
    $0 --only-matrix

    # Skip integration tests (faster)
    $0 --skip-integration

    # Run only linting
    $0 --only-lint

ENVIRONMENT VARIABLES:
    LATTICE_IMAGE           Docker image to use for integration tests (default: ghcr.io/latticehq/lattice)
    TF_ACC                  Enable Terraform acceptance tests (automatically set to "1")

EOF
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_deps=()
    
    # Check Go
    if ! command -v go &> /dev/null; then
        missing_deps+=("go")
    else
        print_success "Go $(go version | awk '{print $3}')"
    fi
    
    # Check Docker (for integration tests)
    if [[ "$RUN_INTEGRATION" == true ]]; then
        if ! command -v docker &> /dev/null; then
            missing_deps+=("docker")
        else
            if docker info &> /dev/null; then
                print_success "Docker $(docker version --format '{{.Server.Version}}')"
            else
                print_error "Docker is installed but not running"
                missing_deps+=("docker (running)")
            fi
        fi
    fi
    
    # Check Terraform (for matrix tests)
    if [[ "$RUN_MATRIX" == true ]]; then
        if ! command -v terraform &> /dev/null; then
            print_warning "Terraform not found - will install versions via tfenv or asdf if available"
        else
            print_success "Terraform $(terraform version -json | jq -r '.terraform_version')"
        fi
        
        # Check for version managers
        if command -v tfenv &> /dev/null; then
            print_success "tfenv available for Terraform version management"
        elif command -v asdf &> /dev/null && asdf plugin list | grep -q terraform; then
            print_success "asdf with terraform plugin available"
        else
            print_warning "Consider installing tfenv or asdf for easier Terraform version management"
        fi
    fi
    
    # Check Make
    if ! command -v make &> /dev/null; then
        missing_deps+=("make")
    else
        print_success "Make available"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                go)
                    echo "  brew install go"
                    ;;
                docker*)
                    echo "  brew install --cask docker"
                    echo "  Or: brew install colima && colima start"
                    ;;
                make)
                    echo "  xcode-select --install"
                    ;;
            esac
        done
        return 1
    fi
    
    echo ""
    return 0
}

run_build() {
    print_header "Build Step"
    
    cd "$PROJECT_DIR"
    
    print_info "Downloading dependencies..."
    go mod download
    
    print_info "Building provider..."
    CGO_ENABLED=0 go build -v .
    
    print_success "Build completed"
    echo ""
}

run_integration_tests() {
    print_header "Integration Tests"
    
    cd "$PROJECT_DIR"
    
    # Check if we can access the Lattice image
    print_info "Using Lattice image: ${LATTICE_IMAGE}"
    
    # Run latticeversion script
    if [ -f "./scripts/latticeversion" ]; then
        print_info "Getting Lattice versions..."
        source <(go run ./scripts/latticeversion)
        
        # Test mainline version
        print_info "Testing with Lattice mainline version: ${LATTICE_MAINLINE_VERSION}"
        LATTICE_VERSION="${LATTICE_MAINLINE_VERSION}" go test -v -timeout 10m ./integration
        print_success "Mainline integration tests passed"
        
        # Test stable version
        print_info "Testing with Lattice stable version: ${LATTICE_STABLE_VERSION}"
        LATTICE_VERSION="${LATTICE_STABLE_VERSION}" go test -v -timeout 10m ./integration
        print_success "Stable integration tests passed"
    else
        print_warning "latticeversion script not found, skipping version-specific tests"
        go test -v -timeout 10m ./integration
    fi
    
    print_success "All integration tests passed"
    echo ""
}

install_terraform_version() {
    local version=$1
    
    # Try tfenv first
    if command -v tfenv &> /dev/null; then
        print_info "Installing Terraform ${version} via tfenv..."
        tfenv install "$version" 2>&1 | grep -v "already installed" || true
        tfenv use "$version"
        return 0
    fi
    
    # Try asdf
    if command -v asdf &> /dev/null && asdf plugin list | grep -q terraform; then
        print_info "Installing Terraform ${version} via asdf..."
        asdf install terraform "$version" 2>&1 | grep -v "already installed" || true
        asdf local terraform "$version"
        return 0
    fi
    
    # Manual installation as fallback
    print_warning "No version manager found. Please install tfenv or asdf."
    print_error "Cannot automatically install Terraform ${version}"
    return 1
}

run_matrix_tests() {
    print_header "Matrix Tests (Terraform Acceptance Tests)"
    
    cd "$PROJECT_DIR"
    
    local failed_versions=()
    local passed_versions=()
    
    for tf_version in "${TERRAFORM_VERSIONS[@]}"; do
        print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "Testing with Terraform ${tf_version}"
        print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Install the Terraform version
        if ! install_terraform_version "$tf_version"; then
            print_error "Failed to install Terraform ${tf_version}"
            failed_versions+=("$tf_version (install failed)")
            continue
        fi
        
        # Verify installation
        local installed_version=$(terraform version -json | jq -r '.terraform_version')
        print_info "Using Terraform ${installed_version}"
        
        # Run acceptance tests
        if TF_ACC=1 go test -v -cover -timeout 10m ./provider/; then
            print_success "Tests passed for Terraform ${tf_version}"
            passed_versions+=("$tf_version")
        else
            print_error "Tests failed for Terraform ${tf_version}"
            failed_versions+=("$tf_version")
        fi
        
        echo ""
    done
    
    # Summary
    print_header "Matrix Test Summary"
    
    if [ ${#passed_versions[@]} -gt 0 ]; then
        echo -e "${GREEN}Passed (${#passed_versions[@]}):${NC}"
        for version in "${passed_versions[@]}"; do
            echo -e "  ${GREEN}✓${NC} Terraform ${version}"
        done
    fi
    
    if [ ${#failed_versions[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed (${#failed_versions[@]}):${NC}"
        for version in "${failed_versions[@]}"; do
            echo -e "  ${RED}✗${NC} Terraform ${version}"
        done
        echo ""
        return 1
    fi
    
    echo ""
    print_success "All matrix tests passed!"
    echo ""
}

run_lint() {
    print_header "Lint Step"
    
    cd "$PROJECT_DIR"
    
    # Setup specific Terraform version for linting
    if command -v tfenv &> /dev/null; then
        tfenv install 1.3.* 2>&1 | grep -v "already installed" || true
        tfenv use 1.3.*
    fi
    
    print_info "Downloading dependencies..."
    go mod download
    
    # Check formatting
    print_info "Checking code formatting..."
    make fmt
    if ! git diff --exit-code; then
        print_error "Code formatting check failed - run 'make fmt' and commit changes"
        return 1
    fi
    print_success "Code formatting OK"
    
    # Check code generation
    print_info "Checking generated code..."
    make gen
    if ! git diff --exit-code; then
        print_error "Generated code is out of date - run 'make gen' and commit changes"
        return 1
    fi
    print_success "Generated code OK"
    
    print_success "All lint checks passed"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            RUN_BUILD=false
            shift
            ;;
        --skip-integration)
            RUN_INTEGRATION=false
            shift
            ;;
        --skip-matrix)
            RUN_MATRIX=false
            shift
            ;;
        --skip-lint)
            RUN_LINT=false
            shift
            ;;
        --only-build)
            RUN_BUILD=true
            RUN_INTEGRATION=false
            RUN_MATRIX=false
            RUN_LINT=false
            shift
            ;;
        --only-integration)
            RUN_BUILD=false
            RUN_INTEGRATION=true
            RUN_MATRIX=false
            RUN_LINT=false
            shift
            ;;
        --only-matrix)
            RUN_BUILD=false
            RUN_INTEGRATION=false
            RUN_MATRIX=true
            RUN_LINT=false
            shift
            ;;
        --only-lint)
            RUN_BUILD=false
            RUN_INTEGRATION=false
            RUN_MATRIX=false
            RUN_LINT=true
            shift
            ;;
        --tf-versions)
            IFS=' ' read -r -a TERRAFORM_VERSIONS <<< "$2"
            shift 2
            ;;
        --all-versions)
            TERRAFORM_VERSIONS=("1.0.*" "1.1.*" "1.2.*" "1.3.*" "1.4.*" "1.5.*" "1.6.*" "1.7.*" "1.8.*")
            shift
            ;;
        --quick)
            TERRAFORM_VERSIONS=("1.8.*")
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header "Terraform Provider Lattice - Local CI Testing"
    
    echo "Configuration:"
    echo "  Build:        ${RUN_BUILD}"
    echo "  Integration:  ${RUN_INTEGRATION}"
    echo "  Matrix:       ${RUN_MATRIX} ${TERRAFORM_VERSIONS[*]:+(${TERRAFORM_VERSIONS[*]})}"
    echo "  Lint:         ${RUN_LINT}"
    echo ""
    
    if ! check_prerequisites; then
        exit 1
    fi
    
    local failed=false
    
    if [[ "$RUN_BUILD" == true ]]; then
        if ! run_build; then
            failed=true
        fi
    fi
    
    if [[ "$RUN_INTEGRATION" == true ]] && [[ "$failed" == false ]]; then
        if ! run_integration_tests; then
            failed=true
        fi
    fi
    
    if [[ "$RUN_MATRIX" == true ]] && [[ "$failed" == false ]]; then
        if ! run_matrix_tests; then
            failed=true
        fi
    fi
    
    if [[ "$RUN_LINT" == true ]] && [[ "$failed" == false ]]; then
        if ! run_lint; then
            failed=true
        fi
    fi
    
    # Final summary
    print_header "Final Summary"
    
    if [[ "$failed" == true ]]; then
        print_error "Some tests failed!"
        exit 1
    else
        print_success "All tests passed! 🎉"
        exit 0
    fi
}

main
