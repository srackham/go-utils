# Go Utils

A collection of Go utility packages for common tasks.

> [!IMPORTANT]
> This project has not been released, is unstable and is not supported. I wrote it for, and use it with, my Go projects.

## Implementation

Each subdirectory is a stand-alone package containing one or more Go source files:

```go
├── assert
│   ├── assert.go
│   └── assert_test.go
├── cache
│   ├── cache.go
│   └── cache_test.go
├── fsx
│   ├── fsx.go
│   └── fsx_test.go
├── helpers
│   ├── helpers.go
│   └── helpers_test.go
└── set
    ├── set.go
    └── set_test.go
```

The module is hosted on Github and the module name is `github.com/srackham/go-utils`.
How can I import a single package e.g.`fsx` into another Go project?

## Examples

```go
package main

import (
    "fmt"
    "github.com/srackham/go-utils/fsx"
)

func main() {
    if fsx.FileExists("somefile.txt") {
        fmt.Println("File exists")
    } else {
        fmt.Println("File does not exist")
    }
}
```

## Todo

- Add AI generated tests.

- set package: ✘ ~Rename the `set` package to `multiset`~
- set package: Add `Decrement` and `Increment` functions to decrement and increment the multiplicity of an element. Raise error if element is not present.
- set package: Rename the `Count` to `GetCount`; add `SetCount` function.
- set package: Multiplicity can go decrement to zero, attempting to decrement further is ok (multiplicity can be less than zero).
- set package: Rename the `Has` function to `Contains` and return true if element is in set and multiplicity is greater than zero.
- set package: Rename `Len` to `Cardinality` (number of distinct elements.
