package set

/*
Multiset type

Maintains a count (multiplicity) of elements whose values are equal but not the element values.

A multiset (also called a _bag_ or _mset_) allows multiple instances of the same element. The number of occurrences of an element is called its _multiplicity_.
*/

type Set[T comparable] map[T]int

// Constructor to create new set
// Example: New[int]() to create a int set
func New[T comparable](values ...T) Set[T] {
	s := make(Set[T])
	s.Add(values...)
	return s
}

// Add values to set
func (s Set[T]) Add(values ...T) {
	for _, value := range values {
		//lint:ignore S1036 we are only testing for value
		if _, ok := s[value]; ok {
			s[value]++
		} else {
			s[value] = 1
		}
	}
}

// Delete values from set
func (s Set[T]) Delete(values ...T) {
	for _, value := range values {
		delete(s, value)
	}
}

// Length of set
func (s Set[T]) Len() int {
	return len(s)
}

// Method to check if element exists in set
func (s Set[T]) Has(value T) bool {
	_, ok := s[value]
	return ok
}

// Count the number of times the value has been added to the set.
func (s Set[T]) Count(value T) int {
	v, ok := s[value]
	if ok {
		return v
	} else {
		return 0
	}
}

// Iterate over set using a callback
func (s Set[T]) Iterate(it func(T)) {
	for v := range s {
		it(v)
	}
}

// Convert set to slice of values
func (s Set[T]) Values() []T {
	values := []T{}
	s.Iterate(func(value T) {
		values = append(values, value)
	})
	return values
}

// Clone set
func (s Set[T]) Clone() Set[T] {
	set := make(Set[T])
	set.Add(s.Values()...)
	return set
}

// Union of two sets
func (s Set[T]) Union(other Set[T]) Set[T] {
	set := s.Clone()
	set.Add(other.Values()...)
	return set
}

// Intersection of two sets
func (s Set[T]) Intersection(other Set[T]) Set[T] {
	set := make(Set[T])
	s.Iterate(func(value T) {
		if other.Has(value) {
			set.Add(value)
		}
	})
	return set
}
