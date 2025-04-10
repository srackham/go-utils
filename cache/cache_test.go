package cache

import (
	"crypto/sha256"
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"github.com/srackham/go-utils/assert"
	"github.com/srackham/go-utils/fsx"
)

// Cache data types.
type Rates map[string]float64    // Key = currency symbol; value = value in USD.
type RatesCache map[string]Rates // Key = date string "YYYY-MM-DD".

func TestRates(t *testing.T) {
	data := make(RatesCache)
	tmpdir, err := os.MkdirTemp("", "xrate")
	cacheFile := filepath.Join(tmpdir, "valuations.json")
	r := New(&data, cacheFile)
	assert.PassIf(t, err == nil, "%v", err)

	err = r.Save()
	assert.PassIf(t, err == nil, "%v", err)
	savedCache := (*r.CacheData)
	err = r.Load()
	assert.PassIf(t, err == nil, "%v", err)
	assert.PassIf(t, reflect.DeepEqual(savedCache, (*r.CacheData)), "expected:\n%v\n\ngot:\n%v", savedCache, (*r.CacheData))

	(*r.CacheData)["2022-06-01"] = make(Rates)
	(*r.CacheData)["2022-06-01"]["USD"] = 1.00
	err = r.Save()
	assert.PassIf(t, err == nil, "%v", err)
	savedCache = (*r.CacheData)
	err = r.Load()
	assert.PassIf(t, err == nil, "%v", err)
	assert.Equal(t, (*r.CacheData)["2022-06-01"]["USD"], 1.00)
	assert.PassIf(t, reflect.DeepEqual(savedCache, (*r.CacheData)), "expected:\n%v\n\ngot:\n%v", savedCache, (*r.CacheData))

	s, err := fsx.ReadFile(r.CacheFile)
	sha := sha256.Sum256([]byte(s))
	assert.PassIf(t, err == nil, "%v", err)
	assert.Equal(t, sha, r.sha256)
	(*r.CacheData)["2022-06-01"]["USD"] = 0.00
	err = r.Save()
	assert.PassIf(t, err == nil, "%v", err)
	assert.NotEqual(t, sha, r.sha256)
	sha = r.sha256
	err = r.Load()
	assert.PassIf(t, err == nil, "%v", err)
	assert.Equal(t, sha, r.sha256)
}
