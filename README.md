# Go Utils

A collection of Go utility packages for common tasks.

> [!IMPORTANT]
> This project has not been released, is unstable and is not supported. I wrote it for, and use it with, my Go projects.

## Implementation

- Each subdirectory is a stand-alone package containing one or more Go source files.

## Todo

### Set package
- ~Rename the `set` package to `multiset`~
- Add `Decrement` and `Increment` functions to decrement and increment the multiplicity of an element. Raise error if element is not present.
- Rename the `Count` to `Multiplicity`.
- Multiplicity can go decrement to zero, attempting to decrement further is ok (multiplicity can be less than zero).
- The `Has` function is true if element is in set and multiplicity is greater than zero.
- Rename `Len` to `Cardinality` (number of distinct elements.

## AI prompts

This section is a scratchpad for writing AI code-generation prompts.

### Generate copy-updates.sh
##### 09-Apr-2025:
Does Go allow relative package imports? For example, two packages in the same directory, one importing the other.

Generate a shell script that recursively searches for all .go files in the current directory then for each .go file:
Recursively search for all same-named files in the ~/projects/ directory then
select the one with the most recent modified date and print it using the `ls -l` command.

Modify the script as follows:

- Use `#!/usr/bin/env bash` as the shebang line.
- Only print the file name if it is newer than the same-named file in the current directory.
- Change `PROJECTS_DIR` to `~/projects/` with a trailing `/`.

Modify the script as follows:

- Copy each of the newer .go files to the current directory overwriting the original file.

Modify the script as follows:

- Set `relative_local_path` to `"${local_go_file#"$PWD"}"` i.e. drop the leading period (`.`).
- Add a `--dry-run` command option to the script.

When I ran this script I got the following error:

```
$ ./gather-updates.sh --dry-run
./gather-updates.sh: illegal option -- -
Invalid option: -
Usage: gather-updates.sh [-d|--dry-run]
```

Please correct the script.

Modify the script as follows:

- Make `PROJECTS_DIR` the first non-option script argument, call it `PROJECT_DIR` and make this option mandatory.
- If the `PROJECT_DIR` argument is not specified print the usage help message and exit.

Modify the script as follows:

- Change the name of variable `PROJECTS_DIR` to `FROM_DIR`.
- The destination directory is hardwired to the current directory (.), change this to a 2nd command mandatory option called `TO_DIR`.

Modify the script as follows:

- Allow FROM_DIR and TO_DIR to by symlinks to a directory.

Correct the following problem: if a symlink to FROM_DIR does not end with a backslash then it is not searched by find, here's what I got (there are .go file in the directory symlinked to /home/srackham/projects):

```
$ ./gather-updates.sh -n ~/projects .
Searching for .go files in destination '.'...
Comparing with counterparts in source '/home/srackham/projects'...
*** DRY RUN MODE ENABLED (-n): No files will be copied. ***
Script finished.
```

Modify the script so that files are copied only if there is a difference between their contents (use sha256sum to check).

Modify the script so that if the source and destination files are the same file they are skipped (compare absolute real path names).

##### 10-Apr-2025:
Use the Go `testing` package functions in place of the third party `assert` package functions in the following Go package test file:

```go
package set

import (
	"testing"

	"github.com/srackham/cryptor/internal/assert"
)

func TestSet(t *testing.T) {
	set1 := New[int]()
	assert.Equal(t, 0, len(set1))
	set1.Add(1, 2, 3, 4, 2, 4)
	assert.Equal(t, 4, len(set1))
	assert.Equal(t, 1, set1.Count(1))
	assert.Equal(t, 2, set1.Count(4))
	assert.Equal(t, 0, set1.Count(42))
	assert.True(t, set1.Has(3))
	assert.False(t, set1.Has(0))
	set2 := New(3, 4, 5, 6, 7, 7)
	assert.Equal(t, 5, len(set2))
	set3 := set1.Union(set2)
	assert.Equal(t, 7, len(set3))
	set4 := set1.Intersection(set2)
	assert.Equal(t, 2, len(set4))
	set5 := New("foo", "bar", "baz", "baz")
	assert.Equal(t, 3, set5.Len())
	assert.True(t, set5.Has("foo"))
	set5.Delete("foo")
	assert.Equal(t, 2, set5.Len())
	assert.False(t, set5.Has("foo"))
}
```
