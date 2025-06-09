@echo off
setlocal enabledelayedexpansion

:: Development helper script for Firestore ODM
:: This script provides common development tasks

:: Colors (Windows compatible)
set "RED=[31m"
set "GREEN=[32m"
set "YELLOW=[33m"
set "BLUE=[34m"
set "NC=[0m"

:: Functions
:print_header
echo ==========================================
echo   Firestore ODM Development Helper
echo ==========================================
goto :eof

:print_success
echo ✅ %~1
goto :eof

:print_warning
echo ⚠️  %~1
goto :eof

:print_error
echo ❌ %~1
goto :eof

:print_info
echo ℹ️  %~1
goto :eof

:: Check if melos is installed
:check_melos
where melos >nul 2>nul
if %errorlevel% neq 0 (
    call :print_error "Melos is not installed globally"
    call :print_info "Installing melos..."
    dart pub global activate melos
    if %errorlevel% equ 0 (
        call :print_success "Melos installed successfully"
    ) else (
        call :print_error "Failed to install melos"
        exit /b 1
    )
) else (
    call :print_success "Melos is available"
)
goto :eof

:: Bootstrap the workspace
:bootstrap
call :print_info "Bootstrapping workspace..."
melos bootstrap
if %errorlevel% equ 0 (
    call :print_success "Workspace bootstrapped"
) else (
    call :print_error "Failed to bootstrap workspace"
    exit /b 1
)
goto :eof

:: Run all quality checks
:check_all
call :print_info "Running all quality checks..."

call :print_info "Checking code format..."
melos run format:check
if %errorlevel% neq 0 (
    call :print_error "Code formatting check failed"
    exit /b 1
)
call :print_success "Code formatting is correct"

call :print_info "Running static analysis..."
melos run analyze
if %errorlevel% neq 0 (
    call :print_error "Static analysis failed"
    exit /b 1
)
call :print_success "Static analysis passed"

call :print_info "Running all tests..."
melos run test:all
if %errorlevel% neq 0 (
    call :print_error "Tests failed"
    exit /b 1
)
call :print_success "All tests passed"

call :print_success "All quality checks passed! 🎉"
goto :eof

:: Fix common issues
:fix_issues
call :print_info "Fixing common issues..."

call :print_info "Formatting code..."
melos run format

call :print_info "Applying automated fixes..."
melos run analyze:fix

call :print_success "Issues fixed"
goto :eof

:: Clean and reset
:clean_all
call :print_info "Cleaning workspace..."
melos run clean
call :print_success "Workspace cleaned"
goto :eof

:: Run example
:run_example
call :print_info "Building example..."
melos run build:example
if %errorlevel% equ 0 (
    call :print_success "Example built successfully"
) else (
    call :print_error "Failed to build example"
    exit /b 1
)
goto :eof

:: Preview version changes
:preview_version
call :print_info "Previewing version changes..."
melos run version:check
goto :eof

:: Show help
:show_help
echo.
echo Usage: %~nx0 [command]
echo.
echo Commands:
echo   setup        - Initial setup (install melos, bootstrap)
echo   check        - Run all quality checks
echo   fix          - Fix common issues (format, analyze)
echo   clean        - Clean build artifacts
echo   example      - Build example project
echo   version      - Preview version changes
echo   publish-dry  - Dry run publishing
echo   help         - Show this help message
echo.
goto :eof

:: Dry run publishing
:publish_dry
call :print_info "Running publish dry run..."
melos run publish:dry-run
call :print_success "Publish dry run completed"
goto :eof

:: Main script logic
call :print_header

set "command=%~1"
if "%command%"=="" set "command=help"

if "%command%"=="setup" (
    call :check_melos
    if %errorlevel% equ 0 call :bootstrap
    if %errorlevel% equ 0 call :print_success "Setup completed! Run 'scripts\dev.bat check' to verify everything works."
) else if "%command%"=="check" (
    call :check_all
) else if "%command%"=="fix" (
    call :fix_issues
) else if "%command%"=="clean" (
    call :clean_all
) else if "%command%"=="example" (
    call :run_example
) else if "%command%"=="version" (
    call :preview_version
) else if "%command%"=="publish-dry" (
    call :publish_dry
) else (
    call :show_help
)