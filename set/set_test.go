package set

import (
	"testing"
)

func TestSet(t *testing.T) {
	// Helper function for clearer error messages
	checkEqual := func(t *testing.T, expected, actual interface{}, msg string) {
		t.Helper() // Marks this function as a test helper
		if expected != actual {
			t.Errorf("%s: expected %v, got %v", msg, expected, actual)
		}
	}

	checkTrue := func(t *testing.T, condition bool, msg string) {
		t.Helper()
		if !condition {
			t.Errorf("%s: expected true, got false", msg)
		}
	}

	checkFalse := func(t *testing.T, condition bool, msg string) {
		t.Helper()
		if condition {
			t.Errorf("%s: expected false, got true", msg)
		}
	}

	set1 := New[int]()
	checkEqual(t, 0, len(set1), "Initial length of set1")

	set1.Add(1, 2, 3, 4, 2, 4) // Adds 1, 2, 3, 4. Duplicates are ignored.
	checkEqual(t, 4, len(set1), "Length of set1 after Add")
	checkEqual(t, 1, set1.Count(1), "set1.Count(1)")
	checkEqual(t, 2, set1.Count(4), "set1.Count(4)") // Assumes Add increments count for existing items
	checkEqual(t, 0, set1.Count(42), "set1.Count(42)")
	checkTrue(t, set1.Has(3), "set1.Has(3)")  // Has might mean Count > 0
	checkFalse(t, set1.Has(0), "set1.Has(0)") // Has might mean Count > 0

	set2 := New(3, 4, 5, 6, 7, 7) // Should contain 3, 4, 5, 6, 7
	checkEqual(t, 5, len(set2), "Length of set2")

	set3 := set1.Union(set2) // {1, 2, 3, 4} U {3, 4, 5, 6, 7} = {1, 2, 3, 4, 5, 6, 7}
	checkEqual(t, 7, len(set3), "Length of set3 (Union)")

	set4 := set1.Intersection(set2) // {1, 2, 3, 4} ∩ {3, 4, 5, 6, 7} = {3, 4}
	checkEqual(t, 2, len(set4), "Length of set4 (Intersection)")

	// Assuming there's a separate implementation or alias for string sets that uses Len() method
	set5 := New("foo", "bar", "baz", "baz") // Should contain "foo", "bar", "baz"
	// If the string set implementation has a Len() method instead of using the builtin len()
	checkEqual(t, 3, set5.Len(), "Initial length of set5")
	checkTrue(t, set5.Has("foo"), "set5.Has(\"foo\") before delete")

	set5.Delete("foo")
	checkEqual(t, 2, set5.Len(), "Length of set5 after delete")
	checkFalse(t, set5.Has("foo"), "set5.Has(\"foo\") after delete")
}
