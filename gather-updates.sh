#!/usr/bin/env bash

# --- Script Description ---
# Recursively finds .go files in the specified destination directory (TO_DIR).
# For each .go file found, it searches the specified source directory (FROM_DIR)
# recursively for a file with the same name. It identifies the newest file among
# those matches in FROM_DIR.
# If that newest file is newer than the file in TO_DIR, it overwrites
# the file in TO_DIR, unless the -n (dry run) option is used.
# FROM_DIR and TO_DIR can be direct paths or symbolic links to directories.

# --- !!! WARNING !!! ---
# This script can OVERWRITE files in the specified TO_DIR.
# Use the -n option for a dry run first to review changes.
# --- !!! WARNING !!! ---

# --- Script Options ---
DRY_RUN=false # Default: Perform actual copy

# --- Usage Function ---
usage() {
  echo "Usage: $(basename "$0") [-n] <FROM_DIR> <TO_DIR>"
  echo ""
  echo "  Compares .go files in TO_DIR with same-named files in FROM_DIR."
  echo "  Recursively finds .go files in TO_DIR."
  echo "  For each, finds the newest same-named file in FROM_DIR."
  echo "  If the file in FROM_DIR is newer, it overwrites the corresponding file in TO_DIR."
  echo ""
  echo "  Options:"
  echo "    -n          Dry run: Show what would be copied without actually copying."
  echo ""
  echo "  Arguments:"
  echo "    FROM_DIR    Mandatory path (or symlink) to the directory for newer source files."
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


# --- Main Logic ---
echo "Searching for .go files in destination '$TO_DIR'..."
echo "Comparing with counterparts in source '$FROM_DIR'..."

if "$DRY_RUN"; then
  echo "*** DRY RUN MODE ENABLED (-n): No files will be copied. ***"
else
  echo "Overwriting files in '$TO_DIR' if a newer version is found in '$FROM_DIR'..."
fi

# Find all .go files recursively in the destination directory (TO_DIR)
# find follows symlinks given as starting points by default.
# Use -print0 and read -d '' for safe handling of filenames
find "$TO_DIR" -type f -name "*.go" -print0 | while IFS= read -r -d $'\0' dest_go_file; do

  # Extract the base filename (e.g., "main.go" from "$TO_DIR/subdir/main.go")
  go_filename=$(basename "$dest_go_file")

  # echo "Found destination Go file: '$dest_go_file' (Filename: '$go_filename')" # Debugging

  # Search recursively within FROM_DIR for files with the exact same name
  # *** Use -L to explicitly follow all symbolic links encountered in FROM_DIR ***
  # *** Removed 2>/dev/null to show potential permission errors ***
  # Use -printf '%T@ %p\n' to get modification time (Unix timestamp) and path
  # Sort numerically (-n) in reverse (-r) based on the timestamp (newest first)
  # Take the first line (head -n 1) which corresponds to the newest file
  # Use cut to remove the timestamp and the space, leaving only the path
  newest_source_match=$(find -L "$FROM_DIR" -type f -name "$go_filename" -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)
  find_exit_status=$? # Capture find's exit status in case the pipe fails early

  # Check if find encountered an error (e.g., permissions) OR if no match was found
  # We check the exit status AND if newest_source_match is empty.
  # If find fails due to permissions *before* finding anything, newest_source_match might be empty but find_exit_status != 0
  if [[ $find_exit_status -ne 0 && -z "$newest_source_match" ]]; then
      echo "Warning: 'find' encountered an error searching for '$go_filename' in '$FROM_DIR'. Check permissions." >&2
      # Decide if you want to 'continue' to the next file or treat this as a critical error
      continue
  fi


  # Check if a matching file was found in FROM_DIR
  if [[ -n "$newest_source_match" ]]; then
    # echo "  Found newest match in source dir: '$newest_source_match'" # Debugging

    # Check if the found source file is newer than the destination go file
    # using the '-nt' (newer than) file test operator. Both operands can be symlinks.
    if [[ "$newest_source_match" -nt "$dest_go_file" ]]; then
      echo "Newer version found in source: '$newest_source_match'"
      echo "  Than destination file:      '$dest_go_file'"

      if "$DRY_RUN"; then
        echo "  DRY RUN (-n): Would copy '$newest_source_match' to overwrite '$dest_go_file'"
      else
        echo "  Copying to overwrite:       '$dest_go_file'"
        # cp follows symlinks in the source by default, but overwrites the target file/symlink itself.
        cp "$newest_source_match" "$dest_go_file"

        # Check if the copy was successful (optional but good practice)
        if [[ $? -ne 0 ]]; then
            echo "  Error: Failed to copy '$newest_source_match' to '$dest_go_file'" >&2
        fi
      fi
    # else
      # Optional: uncomment to see which files were found but not newer
      # echo "  Skipping: Source '$newest_source_match' is not newer than destination '$dest_go_file'"
    fi
  # else
    # Optional: uncomment to show which go files had no match in source dir
    # This case is now also reached if find failed AND produced no output.
    # The warning above handles the find error case more specifically.
    # echo "  No file named '$go_filename' found in '$FROM_DIR/' or find failed before finding it."
  fi
done

echo "Script finished."
