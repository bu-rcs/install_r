#!/bin/bash -l

old_version=$1
new_version=$2

echo "Old R version to be used is $old_version"
echo "New R version to be used is $new_version"

module load R/$old_version

R_SCRIPT="/share/pkg.8/r/list_packages.R"
OUTPUT_FILE="installed_r_packages.txt"

# Check if R is on the Path
if ! command -v Rscript &> /dev/null; then
    echo "Error: R/$old_version is not instaleld or not in PATH"
    exit 1
fi

# Run the R script
echo "Running R script to list installed packages..."
Rscript "$R_SCRIPT"

# Check if the output file was created successfully
if [ -f "$OUTPUT_FILE" ]; then
    echo "Success! List of installed R packages saved to $OUTPUT_FILE"
    echo "Total packages found: $(wc -l < "$OUTPUT_FILE")"
else
    echo "Error: Failed to create output file"
    exit 1
fi

# Load new version of R
module purge
module load R/$new_version
module load gcc/12.2.0
module load cmake/3.22.2

Rscript /share/pkg.8/r/install_packages.R

