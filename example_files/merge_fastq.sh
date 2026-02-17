#!/bin/bash

# Script to merge FASTQ files from subfolders
# Usage: ./merge_fastq.sh <parent_folder>

set -euo pipefail

# Check arguments
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <parent_folder>"
    echo "Example: $0 LdRES_8166"
    exit 1
fi

PARENT_DIR="$1"

# Check if parent directory exists
if [[ ! -d "$PARENT_DIR" ]]; then
    echo "Error: Directory '$PARENT_DIR' does not exist"
    exit 1
fi

echo "Processing subfolders in: $PARENT_DIR"
echo "=========================================="

# Iterate through subfolders
for subfolder in "$PARENT_DIR"/*/; do
    # Remove trailing slash and get basename
    subfolder="${subfolder%/}"
    subfolder_name=$(basename "$subfolder")
    
    echo ""
    echo "Processing: $subfolder_name"
    echo "------------------------------------------"
    
    # Define output filenames
    output_r1="${subfolder}/${subfolder_name}_1.fq.gz"
    output_r2="${subfolder}/${subfolder_name}_2.fq.gz"
    
    # Find input files (excluding any already merged files)
    # Using find to get files matching *_1.fq.gz but NOT the output file
    mapfile -t files_r1 < <(find "$subfolder" -maxdepth 1 -name "*_1.fq.gz" -type f | sort)
    mapfile -t files_r2 < <(find "$subfolder" -maxdepth 1 -name "*_2.fq.gz" -type f | sort)
    
    # Check if there are files to merge
    if [[ ${#files_r1[@]} -eq 0 ]] && [[ ${#files_r2[@]} -eq 0 ]]; then
        echo "  No *_1.fq.gz or *_2.fq.gz files found, skipping..."
        continue
    fi
    
    # Process R1 files
    if [[ ${#files_r1[@]} -gt 0 ]]; then
        echo "  Found ${#files_r1[@]} R1 files to merge"
        
        # Calculate expected size (sum of all input files)
        expected_size_r1=0
        for f in "${files_r1[@]}"; do
            size=$(stat -c%s "$f")
            expected_size_r1=$((expected_size_r1 + size))
        done
        
        # Merge R1 files
        echo "  Merging R1 files to: $output_r1"
        cat "${files_r1[@]}" > "$output_r1"
        
        # Verify merge
        if [[ -f "$output_r1" ]]; then
            actual_size_r1=$(stat -c%s "$output_r1")
            if [[ "$actual_size_r1" -eq "$expected_size_r1" ]]; then
                echo "  ✓ R1 merge verified (size: $actual_size_r1 bytes)"
                echo "  Removing original R1 files..."
                rm "${files_r1[@]}"
                echo "  ✓ Original R1 files removed"
            else
                echo "  ✗ ERROR: R1 size mismatch! Expected: $expected_size_r1, Got: $actual_size_r1"
                echo "    Original files NOT removed"
            fi
        else
            echo "  ✗ ERROR: R1 output file was not created"
        fi
    else
        echo "  No R1 files (*_1.fq.gz) found"
    fi
    
    # Process R2 files
    if [[ ${#files_r2[@]} -gt 0 ]]; then
        echo "  Found ${#files_r2[@]} R2 files to merge"
        
        # Calculate expected size
        expected_size_r2=0
        for f in "${files_r2[@]}"; do
            size=$(stat -c%s "$f")
            expected_size_r2=$((expected_size_r2 + size))
        done
        
        # Merge R2 files
        echo "  Merging R2 files to: $output_r2"
        cat "${files_r2[@]}" > "$output_r2"
        
        # Verify merge
        if [[ -f "$output_r2" ]]; then
            actual_size_r2=$(stat -c%s "$output_r2")
            if [[ "$actual_size_r2" -eq "$expected_size_r2" ]]; then
                echo "  ✓ R2 merge verified (size: $actual_size_r2 bytes)"
                echo "  Removing original R2 files..."
                rm "${files_r2[@]}"
                echo "  ✓ Original R2 files removed"
            else
                echo "  ✗ ERROR: R2 size mismatch! Expected: $expected_size_r2, Got: $actual_size_r2"
                echo "    Original files NOT removed"
            fi
        else
            echo "  ✗ ERROR: R2 output file was not created"
        fi
    else
        echo "  No R2 files (*_2.fq.gz) found"
    fi
done

echo ""
echo "=========================================="
echo "Done!"