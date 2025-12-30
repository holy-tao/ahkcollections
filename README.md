# ahk-template
Miscellaneous collections and collection-related utilities for my personal AHK library. Clone into a library directory and see the scripts themselves for detailed documentation.

## Contents
### [Readonly/](./Readonly/)
Various read-only collections. These are collections that cannot be modified after they are created; attempting to do so throws a [`ReadOnlyError`](./Readonly/ReadOnlyError.ahk).

### [Query.ahk](./Query.ahk)
Provides [Linq](https://learn.microsoft.com/en-us/dotnet/csharp/linq/)-like functionality for [enumerable](https://www.autohotkey.com/docs/v2/Objects.htm#__Enum) AHK objects, allowing you to chain operators together and defer actual enumeration until it's absolutely required.

```autohotkey
vals := [1.5, 2.2, 3.4, -10, 4.9999, 5.0001, 1.3]
queryResult := Query(vals)
    .Select((val) => Round(val, 0))
    .Where((val) => val >= 2)
    .Distinct()
; When enumerated, queryResult yields [2, 3, 5]
```

Query's naming conventions are modelled off of C# / .NET's. Similar concepts also exist in languages like JavaScript (e.g. .NET's [`IEnumerable::Where`](https://learn.microsoft.com/en-us/dotnet/api/system.linq.enumerable.where?view=net-10.0) roughly mapes ont JavaScript's [`Array::filter`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/filter)).

A `Query` object stores information about a series of operations to be performed on some set of data. The actual operations are deferred for as long as possible, meaning that the object is not actually enumerated until the query itself is enumerated, either by passing it into a for-loop or by calling a collection or aggregation method like `ToArray` or `Count`. 

For example, in the following snippet, `MsgBox` is never called:
```autohotkey
msgBoxQuery := Query(["one", "two", "three"])
    .Select(val => MsgBox(val))
```

The selector (`val => MsgBox(val)`) is only invoked when the query is actually enumerated:
```autohotkey
for(val in msgBoxQuery){
    ; MsgBox is called in the for-loop
}

; MessageBoxes would also appear here
items := msgBoxQuery.Count()
```