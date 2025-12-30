#Requires AutoHotkey v2.0

; To avoid dependencies on my extensions library for ultimately trivial things, re-define them here
; https://github.com/holy-tao/AhkExtensions
VarRef.DefineProp("Empty", { Call: (*) => &empty := "" })
Integer.DefineProp("Max", { Get: (self) => 0x7FFFFFFFFFFFFFFF })
Integer.DefineProp("Min", { Get: (self) => 0x8000000000000000 })

/**
 * Provides Linq-like query functionality for enumerable objects. Queries can be applied
 * to any {@link https://www.autohotkey.com/docs/v2/Objects.htm#__Enum enumerable object},
 * and will wrap it in a `Query` object. The `Query` is enumerable and can be passed into
 * a for-loop, or the final value can be retrieved with collection operations like
 * {@link Query.Prototype.ToArray `ToArray`}. Queries never modify the queried collection.
 * 
 *          vals := [1.5, 2.2, 3.4, -10, 4.9999, 5.0001, 1.3]
 *          queryResult := Query(vals)
 *              .Select((val) => Round(val, 0))
 *              .Where((val) => val >= 2)
 *              .Distinct()
 *          ; When enumerated, queryResult yields [2, 3, 5]
 * 
 * Wherever possible, query execution is deferred until the `Query` object itself is enumerated
 * either by the caller or by a builtin function like {@link Query.Prototype.Count `Count`}. This
 * avoids unnecessary temporary arrays and improves performance by allowing enumeration to quit
 * early in some cases.
 */
class Query {

;@region Constructor & Enumerator

    _operations := unset
    _enumerator := unset
    _enumVars := unset

    /**
     * Starts a new query.
     * @param {Any} enumerable an {@link https://www.autohotkey.com/docs/v2/lib/Enumerator.htm enumerator}
     *          or enumerable object to query.
     * @param {Integer} enumVars if `enumerable` is an object, the number of variables to pass to its 
     *          {@link https://www.autohotkey.com/docs/v2/Objects.htm#__Enum `__Enum`} method
     *          of `enumerable`. Default is 1, except if `enumerable` is a `Map`, in which case it is
     *          2. When using operations like {@link Query.Prototype.Where `Where`}, this determines
     *          the number of arguments the function must accept. 
     */
    __New(enumerable, enumVars?) {
        this._enumVars := enumVars ?? (enumerable is Map ? 2 : 1)
        this._operations := []
        this._enumerator := HasMethod(enumerable, "__Enum") ? enumerable.__Enum(this._enumVars) : enumerable
    }

    /**
     * Retrieves the next matching item in the query.
     * 
     * This method ***must*** remain {@link https://www.autohotkey.com/docs/v2/lib/Enumerator.htm#Call enumerator-compatible}.
     * 
     * @param {VarRef<Any>} output output parameter that receives the enumerated value
     * @returns {Boolean} 1 if there is a next value, 0 if not 
     */
    Call(&output) {
        ; Initial accumulator value is an array of VarRefs sent to the
        ; queried object's enumerator.

        output := Query.Skip()
        while(output is Query.Skip) {
            accumulator := Array()
            Loop(this._enumVars)
                accumulator.Push(VarRef.Empty())

            if(!this._enumerator.Call(accumulator*))
                break
            
            ; Need to dereference accumulator values explicitly
            for(i, val in accumulator)
                accumulator[i] := %val%

            for(operation in this._operations) {
                ; Auto-unpack - this allows for more natural usage with conditions and selectors
                ; while still letting us zip items together or call enumerators with more than 
                ; one param. In effect a selector returning an array with one item or just the item
                ; does the same thing.
                accumulator := HasMethod(accumulator, "__Enum") ? 
                    operation.Call(accumulator*) : 
                    operation.call(accumulator)
                
                if(accumulator is Query.Skip || accumulator is Query.End){
                    break
                }
            }

            output := accumulator
        }

        ; Expand one-item arrays to just be their contents
        output := Query._Unpack(output)

        return !(output is Query.Skip || output is Query.End)
    }

;@endregion

;@region Filtering
    /**
     * Filters values by some condition. Only values for which `condition` returns a truthy
     * value are included in the resulting query.
     * 
     *          Query([1, 2, 3, 4, 5])
     *              .Where((val) => val > 2)
     *          ; [3, 4, 5]
     * 
     * Query execution is deferred 
     * 
     * @param {Func(Any) => Boolean} condition the condition with which to filter values
     * @returns {Query} the same query for chaining
     */
    Where(condition) {
        this._operations.Push(WhereOp.Bind(condition))
        return this

        WhereOp(condition, params*) => condition.Call(params*) ? params : Query.Skip()
    }

    /**
     * Filters values by {@link https://www.autohotkey.com/docs/v2/Variables.htm#is type}
     * 
     * @param {Class} typ the type to check. Only values of this type are included
     *          in the resulting query.
     * @returns {Query} the same query, for chaining
     */
    OfType(typ) {
        if(!(typ is Class)) {
            throw TypeError("Expected a Class but got a(n) " . Type(typ), -1, type)
        }

        return this.Where((val) => val is typ)
    }
;@endregion

;@region Projection
    /**
     * Projects values that are based on a transform function.	
     * 
     *          Query([1, 2, 3])
     *              .Select((v) => v * 2)
     *          ; [2, 4, 6]
     * 
     * Query execution is deferred
     * 
     * @param {Func(Any) => Any} selector the transform function
     * @returns {Query} the same query for chaining
     */
    Select(selector) {
        this._operations.Push(selector)
        return this
    }

    /**
     * Projects sequences of values that are based on a transform function and then flattens 
     * them into one sequence. This method forces query execution.
     *  
     *          strings := ["The quick brown fox", "jumped over the lazy dog"]
     *          Query(strings)
     *              .SelectMany((str) => StrSplit(str, " "))
     *          ;["The", "quick", "brown", "fox", "jumped", "over", "the", "lazy", "dog"]
     * 
     * @param {Func(Any) => Enumerable} selector the transform function. The transform must 
     *          return enumerable objects
     * @param {Integer} enumVals the number of parameters to pass to the {@link https://www.autohotkey.com/docs/v2/Objects.htm#__Enum `__Enum`}
     *          method of the values returned by the selector (default: 1)
     */
    SelectMany(selector, enumVals := 1) {
        newQuery := Array()

        for(val in this){
            projected := selector.Call(val)
            if(projected is Query.Skip)
                continue

            for(val in projected)
                newQuery.Push(val)
        }

        return Query(newQuery)
    }
;@endregion

;@region Set Operations

    /**
     * Removes duplicate values from a collection. Duplicates are identified using a Map;
     * for more granular control over duplicate detection, use {@link Query.Prototype.DistinctBy `DistinctBy`}
     * 
     *          Query([1, 1, 2, 2, 3, 3]).Distinct()
     *          ;[1, 2, 3]
     * 
     * Query execution is deferred.
     * 
     * @returns {Query} the query object for chaining
     */
    Distinct() {
        this._operations.Push(DistinctOp.Bind(Map()))
        return this

        DistinctOp(found, candidate) {
            if(found.Has(candidate))
                return Query.Skip()

            found[candidate] := 0
            return candidate
        }
    }

    /**
     * Removes duplicate values from a collection using a custom equality comparer
     * 
     *          Query(["One", "Two", "Three", "Four", "Five", "Six"])
     *              .DistinctBy((left, right) => SubStr(left, 1, 1) == SubStr(right, 1, 1))
     *          ;["One", "Two", "Four", "Six"]
     * 
     * Query execution is deferred.
     * 
     * @param {Func(Any, Any) => Boolean} comparer The function to use to determine
     *          equality. The function must take two values and return a truthy value
     *          if they are equal and a falsy value if not
     * @returns {Query} the query object for chaining
     */
    DistinctBy(comparer) {
        this._operations.Push(DistinctByOp.Bind(comparer, Array()))
        return this

        DistinctByOp(comparer, found, candidates*) {
            if(Query(found).Any(comparer.Bind(candidates*)))
                return Query.Skip()

            found.Push(Query._Unpack(candidates))
            return Query._Unpack(candidates)
        }
    }

    /**
     * Returns the set union, which means unique elements that appear in either of two collections.
     * Values are compared as Map keys.
     * 
     * Query execution is deferred
     * 
     * @param {Enumerable} other any enumerable object containing values to union with the current
     *          query 
     */
    Union(other) {
        return this.Chain(other).Distinct()
    }

    /**
     * Returns the set union, which means unique elements that appear in either of two collections,
     * using a custom equality comparer.
     * 
     * Query execution is deferred.
     * 
     * @param {Enumerable} other any enumerable object containing values to union with the current
     *          query 
     * @param {Func(Any, Any) => Boolean} comparer The function to use to determine
     *          equality. The function must take two values and return a truthy value
     *          if they are equal and a falsy value if not
     */
    UnionBy(other, comparer) {
        return this.Chain(other).DistinctBy(comparer)
    }

    /**
     * Returns the set difference, which means the elements of this collection that don't 
     * appear in a second collection.
     * 
     * This forces enumeration of the `other`, but enumeration of the current query is
     * deferred.
     * 
     * @param {Enumerable} other any enumerable object containing values to exclude from
     *          enumeration of this query
     * @returns {Query} the same query, for chaining
     */
    Except(other) {
        otherMap := Map()
        for(value in other){
            otherMap[value] := 1
        }

        this._operations.Push(ExceptOp.Bind(otherMap))
        return this

        ExceptOp(otherMap, candidate) {
            return otherMap.Has(candidate) ? Query.Skip() : candidate
        }
    }

    /**
     * Returns the set difference, which means the elements of this collection that don't 
     * appear in a second collection according to a caller-supplied equality comparer.
     * 
     * Enumeration is deferred, but `other` is enumerated once for every item in the query.
     * 
     * @param {Enumerable} other any enumerable object containing values to exclude from
     *          enumeration of this query
     * @param {Func(Any, Any) => Boolean} comparer The function to use to determine
     *          equality. The function must take two values and return a truthy value
     *          if they are equal and a falsy value if not
     * @returns {Query} the same query, for chaining
     */
    ExceptBy(other, comparer) {
        this._operations.Push(ExceptByOp.Bind(other, comparer))
        return this

        ExceptByOp(other, comparer, candidates*) {
            if(Query(other).Any(comparer.Bind(candidates*)))
                return Query.Skip()

            return Query._Unpack(candidates)
        }
    }

    /**
     * Returns the set intersection, which means elements that appear in *both* this query and
     * `other`.
     * 
     * Enumeration of this query is deferred, but `other` is enumerated immediately.
     * 
     * @param {Enumerable} other any enumerable object
     * @returns {Query} the same query, for chaining
     */
    Intersect(other) {
        otherMap := Map()
        for(value in other){
            otherMap[value] := 1
        }

        this._operations.Push(IntersectOp.Bind(otherMap))
        return this

        IntersectOp(otherMap, candidate) {
            return otherMap.Has(candidate) ? candidate : Query.Skip()
        }
    }

    /**
     * Returns the set intersection, which means elements that appear in *both* this query and
     * `other` according to a caller-supplied equality comparer
     * 
     * Enumeration of this query is deferred.
     * 
     * @param {Enumerable} other any enumerable object
     * @returns {Query} the same query, for chaining
     */
    IntersectBy(other, comparer) {
        this._operations.Push(IntersectByOp.Bind(other, comparer))
        return this

        IntersectByOp(other, comparer, candidates*) {
            if(Query(other).Any(comparer.Bind(candidates*)))
                return Query._Unpack(candidates)

            return Query.Skip()
        }
    }
;@endregion

;@region Partitioning

    /**
     * Skips elements in the sequence
     * 
     * @param {Integer} count the number of elements to skip. Must be non-negative
     * @returns {Query} the query, for chaining
     */
    Skip(count) {
        if((count := Integer(count)) < 0)
            throw ValueError("Count must be non-negative", -1, count)

        this._operations.Push(SkipOp.Bind(count, &counter := 0))
        return this

        SkipOp(count, &counter, value) {
            return counter++ < count ? Query.Skip() : value
        }
    }

    /**
     * Skips elements until an element is encountered that does not satisfy some
     * condition.
     * 
     * @param {Func(Any) => Boolean} condition the condition to evaluate. Elements
     *          are skipped until this condition returns a falsy value
     * @returns {Query} the query, for chaining 
     */
    SkipWhile(condition) {
        this._operations.Push(SkipWhileOp.Bind(condition, &keepSkipping := true))
        return this

        SkipWhileOp(condition, &keepSkipping, value) {
            if(keepSkipping && (keepSkipping := condition.Call(value))){
                return Query.Skip()
            }

            return value
        }
    }

    /**
     * Takes elements up to a specified position in the sequence.
     * 
     * @param {Integer} count the number of elements to take
     * @returns {Query} the query, for chaining 
     */
    Take(count) {
        if((count := Integer(count)) < 0)
            throw ValueError("Count must be non-negative", -1, count)

        this._operations.Push(TakeOp.Bind(count, &counter := 0))
        return this

        TakeOp(count, &counter, value) {
            return counter++ < count ? value : Query.End()
        }
    }

    /**
     * Takes elements until an element is encountered which does not satisfy
     * a caller-supplied condition.
     * 
     * @param {Funct(Any) => Boolean} condition the condition to check
     * @returns {Query} the query, for chaining 
     */
    TakeWhile(condition) {
        this._operations.Push(TakeWhileOp.Bind(condition))
        return this

        TakeWhileOp(condition, value) {
            if(condition.Call(value))
                return value

            return Query.End()
        }
    }

    /**
     * Split the elements of a sequence into chunks of size at most `size`. Each chunk
     * is an Array.
     * @param {Integer} size the maximum size of each chunk
     * @returns {Query.Chunked} a query that, when enumerated, returns chunks from this
     *          one
     */
    Chunk(size) {
        if((size := Integer(size)) <= 0)
            throw ValueError("Chunk size must be greater than 0", -1, size)

        return Query.Chunked(this, size, this._enumVars)
    }

    class Chunked extends Query {
        __New(source, size, enumVars) {
            this._chunkSize := size
            this._enumVars := enumVars
            this._enumerator := source

            this._operations := []
        }

        Call(&output) {
            chunk := []
            while(chunk.Length < this._chunkSize && super.Call(&sourceOutput := "")) {
                chunk.Push(sourceOutput)
            }
            
            output := chunk
            return chunk.Length > 0
        }
    }

    /**
     * Groups elements that share a common attribute, determined by a selector.
     * 
     *          vals := [{A: 1, B, 2}, {A: 1, B, 3}, {A: 2, B, 4}]
     *          groups := vals
     *              .GroupBy(v => v.A)
     *              .Count() ; 2
     * 
     * Downstream 
     * 
     * @param {Func(Any) => Any} selector A function that, when applied to the contents
     *          of the query, returns the value by which to group its items
     */
    GroupBy(selector) {
        return Query.Grouped(this, selector)
    }

    class Grouped extends Query {
        __New(source, selector){
            this._source := source
            this._selector := selector
            this._grouped := false

            this._enumVars := 2
            this._operations := []
        }

        Call(&output) {
            if(!this._grouped){
                this._enumerator := this._Group().__Enum(2)
                this._grouped := true
            }
            
            return super.Call(&output)
        }

        _Group(){
            groupMap := Map()

            for(val in this._source){
                key := this._selector.Call(val)

                if(!groupMap.Has(key)){
                    groupMap[key] := Array()
                }

                groupMap[key].Push(val)
            }
            
            return groupMap
        }
    }

;@endregion

;@region Sorting

    /**
     * Sorts the elements in the query according to a caller-provided comparison function.
     * Callers can use `ThenBy` on the resulting query to add additional comparison functions
     * which can distinguish between values that previous comparison functions determined were
     * equivalent.
     * 
     * Execution of the query is deferred, but callers should note that sorting requires the
     * query to execute all operations up until the OrderBy to completion. OrderBy collects the
     * elements if the query into a single-dimensional array.
     * 
     * @param {Func(Any, Any) => Number} comparer the comparison function. This function must
     *          take two values `left` and `right`, and return a Number indicating their
     *          relationship:
     *              - A negative number indicates that `right` > `left`
     *              - 0 indicates that the values are equal
     *              - A positive number indicates that `left` > `right`
     * @returns {Query.Sorted} a new query that will enumerate the contents of this query
     *          in sorted order
     * 
     * @example <caption>Sort a list of numbers in ascending order</caption>
     * numbers := [10, 4, -5, 4, 1, 2, -98, 43]
     * sorted := Query(numbers)
     *      .OrderBy((left, right) => left - right)
     *      .ToArray()
     */
    OrderBy(comparer) {
        return Query.Sorted(this, comparer, this._enumVars)
    }

    /**
     * Reverses elements in the query. Reverse will collect the elements in the query into a
     * single-dimensional Array
     */
    Reverse() {
        return Query.Reversed(this, this._enumVars)
    }

    /**
     * A utility class that defers sorting until it's called
     */
    class Sorted extends Query {

        /**
         * Creates a new Query.Sorted object but doesn't actually sort anything
         * @param {Query} source the source query to sort 
         * @param {Func(Any, Any) => Integer} comparer comparision function 
         */
        __New(source, comparer, enumVars) {
            this._source := source
            this._comparers := [comparer]
            this._isSorted := false
            this._sortedArray := []

            this._enumVars := enumVars
            this._operations := []
        }

        Call(&output) {
            if(!this._isSorted){
                this._CollectAndSortElements()
            }

            return super.Call(&output)
        }

        ThenBy(comparer) {
            this._comparers.Push(comparer)
            return this
        }

        _CollectAndSortElements() {
            collected := this._source.ToArray()
            this._QuickSort(collected, this._comparers)
            this._enumerator := collected.__Enum(1)

            this._isSorted := true
        }

        _QuickSort(arr, comparators, low?, high?){
            low := low ?? 1
            high := high ?? arr.Length

            ;Quit early
            if(low >= high || low <= 0 || arr.Length < 2)
                return

            if(low < high){
                pivot := this._Partition(arr, comparators, low, high)

                this._QuickSort(arr, comparators, low, pivot - 1)		;Sort left side
                this._QuickSort(arr, comparators, pivot + 1, high)		;Sort righ tside
            }
        }

        _Partition(arr, comparators, low, high){
            pivot := arr[high]
            i := low

            ;In normal languages, for(j = low, j < high, j++)
            Loop(high - low){
                j := A_Index - 1 + low

                diff := 0
                for(comparator in comparators) {
                    diff := comparator.Call(arr[j], pivot)
                    if(diff != 0)
                        break
                }

                if(diff <= 0){
                    this._Swap(arr, i, j)
                    i += 1
                }
            }

            this._Swap(arr, i, high)
            return i
        }
	
        _Swap(arr, index1, index2){
            temp := arr[index1]
            arr[index1] := arr[index2]
            arr[index2] := temp
        }
    }

    /**
     * A utility class that defers reversal until it's called
     */
    class Reversed extends Query {
        __New(source, enumVars) {
            this._source := source
            this._isReversed := false

            this._enumVars := enumVars
            this._operations := []
        }

        Call(&output) {
            if(!this._isReversed) {
                this._Reverse()
            }

            return super.Call(&output)
        }

        _Reverse() {
            arr := this._source.ToArray()

            Loop(arr.Length // 2){
                this._Swap(arr, A_Index, arr.Length - (A_Index - 1))
            }

            this._enumerator := arr.__Enum(1)
            this._isReversed := true
        }

        _Swap(arr, index1, index2){
            temp := arr[index1]
            arr[index1] := arr[index2]
            arr[index2] := temp
        }
    }

;@endregion Sorting

;@region Quantifiers
    /**
     * Counts the number of elements returned by the query, forcing
     * query execution
     */
    Count() {
        i := 0
        for(val in this)
            i++
        return i
    }

    /**
     * Determines whether any element of a sequence exists or satisfies a condition.
     * 
     * This starts query execution, but execution is short-circuited if `condition` is
     * met.
     * 
     * @param {Func(Any) => Bool} condition Condition to check. If unset, `Any` checks
     *          for the existence of at least one element in the query results.
     * @returns {Boolean} 1 if any element satisfies `condition`, 0 otherwise
     */
    Any(condition?) {
        for(val in this){
            if(!IsSet(condition))
                return true ; No condition, since the enumerator returned something we're good

            if(condition.Call(val))
                return true
        }

        return false
    }

    /**
     * Determines whether all elements of a sequence satisfy a condition. 
     * 
     * This starts query execution, but it may short-circuit if an element is
     * encountered which does not satisfy `condition`.
     * 
     * @param {Func(Any) => Boolean} condition Condition to check
     * @returns {Boolean} 1 if all elements satisfy `condition`, 0 otherwise
     */
    All(condition) {
        for(val in this) {
            if(!condition.Call(val))
                return false
        }

        return true
    }

    /**
     * Determines whether or not the sequence contains a value
     * 
     * @param {Any} value value to search for
     * @returns {Boolean} true if for any element in the sequence, `e == value`,
     *          false otherwise 
     */
    Contains(value) {
        return this.Any((element) => element == value)
    }

    /**
     * Returns the maximum value in the sequence. All values must be 
     * {@link https://www.autohotkey.com/docs/v2/lib/Number.htm Numbers}.
     * 
     * @returns {Number} the maximum value in the sequence
     */
    Max() {
        return Max(this.ToArray()*)
    }

    /**
     * Returns the maximum value in the sequence when compared according to the
     * value retrieved by some projection.
     * 
     *      words := ["The", "Quick", "Brown", "Fox", "Jumped", "Over", "The", "Lazy", "Dog"]
     *      longest := Query(words).MaxBy(word => StrLen(word)) ; "Jumped"
     * 
     * @param {Func(Any) => Number} getter a function that projects each value
     *          in the sequence to a {@link https://www.autohotkey.com/docs/v2/lib/Number.htm Number}
     * @returns {Any} the maximum value in the sequence
     */
    MaxBy(getter) {
        maxItem := "", maxNum := Integer.Min

        for(candidate in this) {
            candidateNum := getter.Call(candidate)
            if(candidateNum > maxNum){
                maxNum := candidateNum
                maxItem := candidate
            }
        }

        return maxItem
    }

    /**
     * Returns the minimum value in the sequence. All values must be 
     * {@link https://www.autohotkey.com/docs/v2/lib/Number.htm Numbers}.
     * 
     * @returns {Number} the minimum value in the sequence
     */
    Min() {
        return Min(this.ToArray()*)
    }

    /**
     * Returns the minimum value in the sequence when compared according to the
     * value retrieved by some projection.
     * 
     *      words := ["The", "Quick", "Brown", "Fox", "Jumped", "Over", "The", "Lazy", "Dog"]
     *      longest := Query(words).MinBy(word => StrLen(word)) ; "The"
     * 
     * @param {Func(Any) => Number} getter a function that projects each value
     *          in the sequence to a {@link https://www.autohotkey.com/docs/v2/lib/Number.htm Number}
     * @returns {Any} the minimum value in the sequence
     */
    MinBy(getter) {
        minItem := "", minNum := Integer.Max

        for(candidate in this) {
            candidateNum := getter.Call(candidate)
            if(candidateNum < minNum){
                minNum := candidateNum
                minItem := candidate
            }
        }

        return minItem
    }

    /**
     * Returns the mean value in the sequence. All values must be {@link https://www.autohotkey.com/docs/v2/lib/Number.htm Numbers}.
     */
    Mean() {
        sum := 0, len := 0

        for(val in this) {
            len++
            sum += val
        }

        return sum / len
    }

    /**
     * Returns the median value in the sequence. All values must be {@link https://www.autohotkey.com/docs/v2/lib/Number.htm Numbers}.
     */
    Median() {
        collected := this
            .OrderBy((l, r) => l - r)
            .ToArray()
        
        if(Mod(collected.Length, 2) == 1){
            return collected[(collected.Length + 1) // 2]
        }
        else{
            return (collected[collected.Length / 2] + collected[(collected.Length / 2) + 1]) / 2
        }
    }
;@endregion

;@region General
    /** 
     * Chains together multiple enumerable objects
     * 
     * @param {Enumerable} enumerators Any number of enumerable objects to enumerate
     *          after this one
     * @returns {Query.Chain} an enumerable object that enumerates this query and the
     *          enumerable objects passed to `Chain` in order
    */
    Chain(enumerators*) {
        if(enumerators.Length == 0)
            return this

        return Query(Query.Chain(this, enumerators*))
    }

    ForEach(function) {
        params := Array(), params.Length := function.MinParams
        Loop(params.Length){
            params[A_Index] := VarRef.Empty()
        }
        
        while(this.Call(&params)){            
            function.Call(params*)
        }
    }

    /**
     * Collects the elements of the query into an Array, forcing
     * query execution
     */
    ToArray() {
        arr := []

        for(val in this)
            arr.Push(val)

        return arr
    }

    /**
     * Collects elements into a map using a mapping function.
     * 
     *      mapped := Query.Range(1, 10)
     *          .ToMap((value) => [String(value), value])
     * 
     * 
     * @param {Func(Any) => [Any, Any]} mapper the mapping function. Must return
     *          an array (or other object which supports `__Item` with integer values)
     *          with two elements; the first element is used as the item's key, the 
     *          second is its value.
     * @param {Boolean} strict if true, if the mapper would overwrite any element, an
     *          error is thrown. Otherwise, map elements can be freely overridden.
     *          Default is false.
     */
    ToMap(mapper, strict := false) {
        outMap := Map()

        for(val in this){
            mapped := mapper.Call(val)
            key := mapped[1], value := mapped[2]

            if(strict && outMap.Has(key))
                throw ValueError("Duplicate keys not allowed in strict mode", -1, key)

            outMap[key] := value
        }

        return outMap
    }

;@endregion

;@region Utilities
    /**
     * Returns an enumerator that returns Numeric values from start to end according
     * to an arbitrary increment
     * 
     * @param {Number} start the starting value (inclusive)
     * @param {Number} end the ending value (inclusive)
     * @param {Number} step the value by which to increment
     * @returns {Query} the resulting query
     */
    static Range(start, end, step := 1) {
        if((end > start && step <= 0) || (end < start) && step >= 0 || step == 0){
            throw ValueError("Range is infinte", -1,
                Format("{1} - {2} with step {3}", start, end, step))
        }

        return Query(RangeEnumerator.Bind(&i := start, end, step))
        
        RangeEnumerator(&i, end, increment, &output) {
            if(i > end)
                return false

            output := i
            i := i + increment

            return true
        }
    }

    /**
     * A Query.Chain is an object that, when enumerated, enumerates each of its children
     * in order
     */
    class Chain {
        __New(enumerators*) {
            this._enumerators := []
            for(i, enum in enumerators) {
                this._enumerators.Push(HasMethod(enum, "__Enum") ? enum.__Enum(1) : enum)
            }

            this._enumIndex := 1
            this._enum := ""
        }

        Call(&output) {
            enum := this._enumerators[this._enumIndex]
            if(!enum.Call(&output)){
                this._enumIndex += 1
                if(this._enumIndex > this._enumerators.Length){
                    return false
                }

                return this.Call(&output)
            }

            return true
        }
    }

    class Skip {
        ; operations can return Query.Skip objects to indicate that the
        ; current value should be skipped during enumeration
    }

    class End {
        ; operations can return Query.End objects to indicate that the
        ; enumeration should end
    }

    static _Unpack(arr) => (arr is Array && arr.Length == 1) ? arr[1] : arr

    ;@endregion
}