#!/usr/bin/env bash

# 09-Apr-2025: SJR: I collaborated with Gemini 2.5 Pro to write this script.

# --- Script Description ---
# Recursively finds .go files in the specified destination directory (TO_DIR).
# For each .go file found, it searches the specified source directory (FROM_DIR)
# recursively for a file with the same name. It identifies the newest file among
# those matches in FROM_DIR (this part remains to select the candidate source file).
# It then compares the SHA256 checksum of the candidate source file and the
# destination file. If the checksums differ, it overwrites the file in TO_DIR,
# unless the -n (dry run) option is used.
# FROM_DIR and TO_DIR can be direct paths or symbolic links to directories.

# --- !!! WARNING !!! ---
# This script can OVERWRITE files in the specified TO_DIR based on content difference.
# Use the -n option for a dry run first to review changes.
# Calculating checksums can be I/O intensive and slower than timestamp checks.
# --- !!! WARNING !!! ---

# --- Script Options ---
DRY_RUN=false # Default: Perform actual copy

# --- Usage Function ---
usage() {
  echo "Usage: $(basename "$0") [-n] <FROM_DIR> <TO_DIR>"
  echo ""
  echo "  Compares .go files in TO_DIR with same-named files in FROM_DIR based on content."
  echo "  Recursively finds .go files in TO_DIR."
  echo "  For each, finds the newest same-named file in FROM_DIR (candidate source)."
  echo "  Compares SHA256 checksums of candidate source and destination file."
  echo "  If checksums differ, it overwrites the file in TO_DIR."
  echo ""
  echo "  Options:"
  echo "    -n          Dry run: Show what would be copied without actually copying."
  echo ""
  echo "  Arguments:"
  echo "    FROM_DIR    Mandatory path (or symlink) to the directory for source files."
  echo "    TO_DIR      Mandatory path (or symlink) to the destination directory with .go files."
  exit 1
}


# --- Command-line argument parsing ---
while getopts "n" opt; do
  case "$opt" in
    n)
      DRY_RUN=true
      ;;
    \?)
      # Invalid option detected by getopts
      usage # Show usage and exit
      ;;
  esac
done
shift $((OPTIND-1)) # Remove processed options from arguments


# --- Validate Mandatory Arguments ---
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
  echo "Error: Both FROM_DIR and TO_DIR arguments are required." >&2
  echo ""
  usage # Show usage and exit
fi

# --- Configuration ---
# Get directories from non-option arguments
FROM_DIR="$1"
TO_DIR="$2"


# --- Helper Function for Directory Check ---
# Checks if a path exists and resolves to a directory (handling symlinks)
check_is_directory() {
  local path="$1"
  local path_desc="$2" # Description like "Source" or "Destination"
  local path_check="${path%/}" # Handle potential trailing slash for checks

  if [[ ! -e "$path_check" ]]; then
    # Path doesn't exist at all (handles broken symlinks implicitly here too, as -e is false for them)
    echo "Error: $path_desc path '$path' not found." >&2
    return 1
  elif [[ ! -d "$path_check" ]]; then
    # Path exists but isn't a directory (could be a file, or a symlink to a file/non-existent target)
    if [[ -L "$path_check" ]]; then
        # It's a symlink, but -d failed, so it's not pointing to a directory
        local target
        target=$(readlink "$path_check")
        echo "Error: $path_desc path '$path' is a symbolic link, but does not point to an existing directory (points to: '$target')." >&2
    else
        # Exists, not a symlink, not a directory -> must be a file or something else
        echo "Error: $path_desc path '$path' exists but is not a directory." >&2
    fi
    return 1
  fi
  # If we passed all checks, it must be a directory or a symlink pointing to one
  return 0
}

# --- Safety Checks ---
if ! check_is_directory "$FROM_DIR" "Source"; then
  exit 1
fi
if ! check_is_directory "$TO_DIR" "Destination"; then
  exit 1
fi

# Check if sha256sum command exists
if ! command -v sha256sum &> /dev/null; then
    echo "Error: 'sha256sum' command not found. Please install it (e.g., part of coreutils)." >&2
    exit 1
fi


# --- Main Logic ---
echo "Searching for .go files in destination '$TO_DIR'..."
echo "Comparing content (SHA256) with counterparts in source '$FROM_DIR'..."

if "$DRY_RUN"; then
  echo "*** DRY RUN MODE ENABLED (-n): No files will be copied. ***"
else
  echo "Overwriting files in '$TO_DIR' if content differs from the newest version found in '$FROM_DIR'..."
fi

# Find all .go files recursively in the destination directory (TO_DIR)
find "$TO_DIR" -type f -name "*.go" -print0 | while IFS= read -r -d $'\0' dest_go_file; do

  go_filename=$(basename "$dest_go_file")

  # Find the newest matching file in the source directory
  newest_source_match=$(find -L "$FROM_DIR" -type f -name "$go_filename" -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)
  find_exit_status=$?

  if [[ $find_exit_status -ne 0 && -z "$newest_source_match" ]]; then
      echo "Warning: 'find' encountered an error searching for '$go_filename' in '$FROM_DIR'. Check permissions." >&2
      continue
  fi

  # Check if a matching file was found in FROM_DIR
  if [[ -n "$newest_source_match" ]]; then
    # echo "  Found candidate source file: '$newest_source_match'" # Debugging

    # *** CONTENT COMPARISON using SHA256 ***
    # Calculate checksums - handle potential errors from sha256sum
    source_checksum=$(sha256sum "$newest_source_match" | cut -d ' ' -f 1)
    source_checksum_status=$?
    dest_checksum=$(sha256sum "$dest_go_file" | cut -d ' ' -f 1)
    dest_checksum_status=$?

    # Check if checksum calculation failed for either file
    if [[ $source_checksum_status -ne 0 ]]; then
        echo "Warning: Could not read/checksum source '$newest_source_match'. Skipping comparison for '$go_filename'." >&2
        # sha256sum prints its own error message (e.g., permission denied)
        continue
    fi
    if [[ $dest_checksum_status -ne 0 ]]; then
        echo "Warning: Could not read/checksum destination '$dest_go_file'. Skipping comparison for '$go_filename'." >&2
        # sha256sum prints its own error message
        continue
    fi

    # Compare the checksums
    if [[ "$source_checksum" != "$dest_checksum" ]]; then
      echo "Content differs for '$go_filename':"
      echo "  Source:      '$newest_source_match' (SHA: ${source_checksum:0:12}...)"
      echo "  Destination: '$dest_go_file' (SHA: ${dest_checksum:0:12}...)"

      if "$DRY_RUN"; then
        echo "  DRY RUN (-n): Would copy source to overwrite destination."
      else
        echo "  Copying source to overwrite destination..."
        cp "$newest_source_match" "$dest_go_file"

        if [[ $? -ne 0 ]]; then
            echo "  Error: Failed to copy '$newest_source_match' to '$dest_go_file'" >&2
        fi
      fi
    else
      # Optional: uncomment to see which files had identical content
      echo "  Content identical for '$go_filename' (Source: '$newest_source_match', Destination: '$dest_go_file'). Skipping."
    fi
  # else
    # Optional: uncomment to show which go files had no match in source dir
    # echo "  No file named '$go_filename' found in '$FROM_DIR/' or find failed before finding it."
  fi
done

echo "Script finished."
