#!/bin/bash
#---------------------------------------------------------------------
# (C) Copyright 2023-2025 supergate
#
# All Rights Reserved
#
# Project Name  : HSC
# File Name     : log_analysis.sh
# Author        : seongbeom <seongbeom@supergate.cc>
# First Created : 2025/11/26
# Last Updated  : 2025-12-10 10:36:59 (by seongbeom)
# Editor        : Cursor, tab size (4)
# Description   :
#     Log analysis tool for EDA compilation and simulation logs.
#     Automatically detects and reports warnings/errors with colored output.
#
#     Usage: ./log_analysis.sh <log_file> [--uvm]
#       ex) ./log_analysis.sh compile.log
#       ex) ./log_analysis.sh simulation.log --uvm
#
#---------------------------------------------------------------------
# File History :
#      * 2025/11/26 : (v01p00,  seongbeom) First Release by 'seongbeom'
#      * 2025/11/27 : (v01p01,  seongbeom) Add the UVM's result parser
#      * 2025/12/10 : (v01p02,  seongbeom) Add optional UVM parsing flag (--uvm)
#                                          Fix false positives for "No Errors/Warnings Found"
# To-Do List   :
#      * 2025/11/26 : (ToDo#00, seongbeom) None
#---------------------------------------------------------------------

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Pattern definitions for log parsing
# These regex patterns define what constitutes warnings and errors in log files
#
# WARNING_PATTERN: Matches actual warning messages
#   - "Warning:" at line start (with optional whitespace, case-insensitive)
#   - "*W," format (Synopsys tools)
#   - "[...Warning...]" or "[...WARNING...]" in brackets (e.g., [Warning], [SG-WARNING])
#   - "Lint" messages
#
# ERROR_PATTERN: Matches actual error messages
#   - "Error:" at line start (with optional whitespace, case-insensitive)
#   - "*E," format (Synopsys tools)
#   - "[...Error...]" or "[...ERROR...]" in brackets (e.g., [Error], [SG-ERROR])
#
# These patterns are designed to catch real errors/warnings while avoiding
# false positives like summary lines, table headers, and report paths.
WARNING_PATTERN="(^[[:space:]]*[Ww]arning:|^[[:space:]]*WARNING:|^\*W,|\[[^]]*[Ww]arning[^]]*\]|\[[^]]*WARNING[^]]*\]|^[[:space:]]*Lint)"
ERROR_PATTERN="(^[[:space:]]*[Ee]rror:|^[[:space:]]*ERROR:|^\*E,|\[[^]]*[Ee]rror[^]]*\]|\[[^]]*ERROR[^]]*\])"

# Function to print colored messages with prefix
print_info() {
    echo -e "${CYAN}[SG-INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[SG-WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[SG-ERROR]${NC} $1"
}

print_debug() {
    echo -e "${GRAY}[SG-DEBUG]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SG-SUCCESS]${NC} $1"
}

# Helper function to extract UVM severity counts from summary lines
# Expected format example: "UVM_ERROR :    5"
get_uvm_count() {
    local level="$1"
    local log="$2"
    local value
    value=$(grep -E "^[[:space:]]*${level}[[:space:]]*:" "$log" 2>/dev/null \
            | awk -F':' '{gsub(/ /,"",$2); print $2}' \
            | tail -n1)
    echo "${value:-0}"
}

# Main log analysis function
# This function analyzes a single log file and reports warnings/errors with details.
# When UVM parsing is enabled, it also parses UVM severity summary and treats
# non-zero UVM_ERROR/UVM_FATAL as errors.
# Parameters:
#   $1: log_file   - Path to the log file to analyze
#   $2: enable_uvm - Optional. Set to "true" or "1" to enable UVM parsing (default: false)
# Returns:
#   0: Success (no errors found, warnings may exist)
#   1: Failure (errors found, UVM_ERROR/UVM_FATAL non-zero when UVM enabled, or file not found)
analyze_log() {
    local log_file="$1"
    local enable_uvm="${2:-false}"

    # Normalize enable_uvm to boolean-like check
    if [ "$enable_uvm" = "true" ] || [ "$enable_uvm" = "1" ] || [ "$enable_uvm" = "--uvm" ]; then
        enable_uvm=1
    else
        enable_uvm=0
    fi

    # Check if log file exists
    if [ -f "$log_file" ]; then
        print_info "Analyzing Log: ${log_file}"

        # Arrays to store matching lines with line numbers
        # Format: "line_number: message_text"
        local warning_lines=()
        local error_lines=()

        # Search for warning patterns and store results with line numbers
        while IFS= read -r line; do
            local formatted_line
            formatted_line="${line/:/: }"
            warning_lines+=("$formatted_line")
        done < <(grep -nE "$WARNING_PATTERN" "$log_file" 2>/dev/null)

        # Search for error patterns and store results with line numbers
        while IFS= read -r line; do
            local formatted_line
            formatted_line="${line/:/: }"
            error_lines+=("$formatted_line")
        done < <(grep -nE "$ERROR_PATTERN" "$log_file" 2>/dev/null)

        # Count the number of warnings and errors found (line-based)
        local warn_count=${#warning_lines[@]}
        local error_count=${#error_lines[@]}

        # Parse UVM severity summary counts (only when UVM parsing is enabled)
        local uvm_info_count=0
        local uvm_warning_count=0
        local uvm_error_count=0
        local uvm_fatal_count=0
        local has_uvm_summary=0

        if [ $enable_uvm -eq 1 ]; then
            uvm_info_count=$(get_uvm_count "UVM_INFO" "$log_file")
            uvm_warning_count=$(get_uvm_count "UVM_WARNING" "$log_file")
            uvm_error_count=$(get_uvm_count "UVM_ERROR" "$log_file")
            uvm_fatal_count=$(get_uvm_count "UVM_FATAL" "$log_file")

            # Detect if UVM summary is actually present (any non-zero value)
            if  [ "$uvm_info_count" -ne 0 ] || \
                [ "$uvm_warning_count" -ne 0 ] || \
                [ "$uvm_error_count" -ne 0 ] || \
                [ "$uvm_fatal_count" -ne 0 ]; then
                has_uvm_summary=1
            fi
        fi

        # Display summary counts
        echo -e "   ${BLUE}-${NC} Warnings found: ${warn_count}"
        echo -e "   ${BLUE}-${NC} Errors found:   ${error_count}"

        # Display UVM severity summary if detected
        if [ $has_uvm_summary -eq 1 ]; then
            echo -e "   ${BLUE}-${NC} UVM_INFO   : ${uvm_info_count}"
            echo -e "   ${BLUE}-${NC} UVM_WARNING: ${uvm_warning_count}"
            echo -e "   ${BLUE}-${NC} UVM_ERROR  : ${uvm_error_count}"
            echo -e "   ${BLUE}-${NC} UVM_FATAL  : ${uvm_fatal_count}"
        fi

        # Display detailed error information if any errors were found
        if [ $error_count -gt 0 ]; then
            echo ""
            print_error "Error Details:"
            for line in "${error_lines[@]}"; do
                echo -e "   ${RED}→${NC} $line"
            done
        fi

        # Display detailed warning information if any warnings were found
        if [ $warn_count -gt 0 ]; then
            echo ""
            print_warn "Warning Details:"
            for line in "${warning_lines[@]}"; do
                echo -e "   ${YELLOW}→${NC} $line"
            done
        fi

        # Evaluate UVM_ERROR / UVM_FATAL as error condition
        local has_uvm_error=0
        if [ "$uvm_error_count" -gt 0 ] || [ "$uvm_fatal_count" -gt 0 ]; then
            has_uvm_error=1
        fi

        # Evaluate UVM_WARNING as warning condition
        local has_uvm_warning=0
        if [ "$uvm_warning_count" -gt 0 ]; then
            has_uvm_warning=1
        fi

        # Determine final status and return appropriate exit code
        # Priority: Errors (including UVM_ERROR/FATAL if enabled) > Warnings (including UVM_WARNING if enabled) > Success
        local has_errors=0
        local has_warnings=0

        # Check for errors
        if [ $error_count -gt 0 ]; then
            has_errors=1
        fi
        if [ $enable_uvm -eq 1 ] && [ $has_uvm_error -eq 1 ]; then
            has_errors=1
        fi

        # Check for warnings
        if [ $warn_count -gt 0 ]; then
            has_warnings=1
        fi
        if [ $enable_uvm -eq 1 ] && [ $has_uvm_warning -eq 1 ]; then
            has_warnings=1
        fi

        # Output final status
        if [ $has_errors -eq 1 ] && [ $has_warnings -eq 1 ]; then
            echo ""
            echo "-----------------------------------"
            if [ $enable_uvm -eq 1 ]; then
                print_error "FAILED - Errors (including UVM) and Warnings detected!"
            else
                print_error "FAILED - Errors and Warnings detected!"
            fi
            echo "-----------------------------------"
            echo ""
            return 1
        elif [ $has_errors -eq 1 ]; then
            echo ""
            echo "-----------------------------------"
            if [ $enable_uvm -eq 1 ] && [ $has_uvm_error -eq 1 ]; then
                print_error "FAILED - UVM_ERROR / UVM_FATAL detected!"
            else
                print_error "FAILED - Errors detected!"
            fi
            echo "-----------------------------------"
            echo ""
            return 1
        elif [ $has_warnings -eq 1 ]; then
            echo ""
            echo "-----------------------------------"
            if [ $enable_uvm -eq 1 ] && [ $has_uvm_warning -eq 1 ]; then
                print_warn "PASSED with Warnings (including UVM)"
            else
                print_warn "PASSED with Warnings"
            fi
            echo "-----------------------------------"
            echo ""
            return 0
        else
            echo "-----------------------------------"
            print_success "PASSED - No issues found"
            echo "-----------------------------------"
            echo ""
            return 0
        fi
    else
        print_error "Log file not found: ${log_file}"
        echo ""
        return 1
    fi
}

# Main entry point for single log file analysis
# This function serves as a wrapper for analyze_log and can be extended
# for additional preprocessing or postprocessing if needed.
# Parameters:
#   $1: log_file   - Path to the log file to analyze
#   $2: enable_uvm - Optional. "--uvm" flag to enable UVM parsing (default: disabled)
main() {
    local log_file="$1"
    local enable_uvm="$2"
    analyze_log "$log_file" "$enable_uvm"
    return $?
}

# Script execution logic - handles both direct execution and sourcing
# 1) Direct execution: ./log_analysis.sh logfile.log [--uvm]
# 2) Sourced in other scripts: source log_analysis.sh; analyze_log "file.log" [true|false]
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Script is being executed directly (not sourced)
    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        print_error "Usage: $0 <log_file> [--uvm]"
        print_error "  log_file: Path to the log file to analyze"
        print_error "  --uvm   : (Optional) Enable UVM severity parsing"
        exit 1
    fi

    # Execute main function and exit with its return code
    main "$1" "$2"
    exit $?
fi
