#Requires AutoHotkey v2.0

#Include ./YUnit/Assert.ahk
#Include ../Query.ahk

class QueryTests {
    Range_Always_ReturnsRange() {
        range := Query.Range(1, 5).ToArray()
        Assert.ArraysEqual(range, [1, 2, 3, 4, 5])
    }

    Range_WithStep_ReturnsRange() {
        range := Query.Range(2, 10, 2).ToArray()
        Assert.ArraysEqual(range, [2, 4, 6, 8, 10])
    }

    ToMap_CollectsToMap() {
        mapped := Query.Range(1, 3).ToMap((value) => [String(value), value])
        Assert.MapsEqual(mapped, Map("1", 1, "2", 2, "3", 3))
    }

    SelectMany_WithStrSplit_Works() {
        strings := ["The quick brown fox", "jumped over the lazy dog"]
        flat := Query(strings).SelectMany((str) => StrSplit(str, " ")).ToArray()

        Assert.ArraysEqual(flat, ["The", "quick", "brown", "fox", "jumped", "over", "the", "lazy", "dog"])
    }

    Distinct_WithNoComparator_Works() {
        dups := [1, 2, 1, 3, 2, 4, 3, 5, 5, 5]
        distinct := Query(dups).Distinct().ToArray()

        Assert.ArraysEqual(distinct, [1, 2, 3, 4, 5])
    }

    DistinctBy_WithComparator_Works() {
        distinctBy := Query(["One", "Two", "Three", "Four", "Five", "Six"])
            .DistinctBy((left, right) => SubStr(left, 1, 1) == SubStr(right, 1, 1))
            .ToArray()

        Assert.ArraysEqual(distinctBy, ["One", "Two", "Four", "Six"])
    }

    Select_ProjectsValues() {
        arr := [1, 2, 3, 4, 5]
        projected := Query(arr).Select((v) => v * 2).ToArray()

        Assert.ArraysEqual(projected, [2, 4, 6, 8, 10])
    }

    Where_FiltersValues() {
        arr := [1, 2, 3, 4, 5]
        filtered := Query(arr).Where((v) => v > 2).ToArray()

        Assert.ArraysEqual(filtered, [3, 4, 5])
    }

    Chain_ChainsCollections() {
        arr1 := [1, 2, 3]
        arr2 := ["three", "four", "five"]
        arr3 := [6, 7, 8]

        chained := Query(arr1).Chain(arr2, arr3).ToArray()
        Assert.ArraysEqual(chained, [1, 2, 3, "three", "four", "five", 6, 7, 8])
    }

    Union_ReturnsUnion() {
        u1 := [1, 2, 3, 4, 5, 6]
        u2 := [1, 4, 3, 7]

        unioned := Query(u1).Union(u2).ToArray()
        Assert.ArraysEqual(unioned, [1, 2, 3, 4, 5, 6, 7])
    }

    Except_ReturnsSetDifference() {
        e1 := [1, 2, 3, 4, 5, 6]
        e2 := [2, 3]

        diff := Query(e1).ExceptBy(e2, (a, b) => a == b).ToArray()
        Assert.ArraysEqual(diff, [1, 4, 5, 6])
    }

    Intersect_ReturnsSetIntersection() {
        i1 := [1, 2, 3, 4, 5, 6]
        i2 := [2, 3, 4, 7, 8]

        intersection := Query(i1).IntersectBy(i2, (a, b) => a == b).ToArray()

        Assert.ArraysEqual(intersection, [2, 3, 4])
    }

    Skip_SkipsValues() {
        skipped := Query.Range(1, 6).Skip(2).ToArray()
        Assert.ArraysEqual(skipped, [3, 4, 5, 6])
    }

    SkipWhile_SkipsValuesUntilConditionIsMet() {
        skipped := Query([1, 2, 3, 4, 5, 6, -2]).SkipWhile((v) => v < 3).ToArray()
        Assert.ArraysEqual(skipped, [3, 4, 5, 6, -2])
    }

    Take_TakesValue() {
        taken := Query.Range(1, 6).Take(4).ToArray()
        Assert.ArraysEqual(taken, [1, 2, 3, 4])
    }

    TakeWhile_TakesValueUntilConditionIsUnmet() {
        taken := Query.Range(1, 6).TakeWhile((v) => v < 3).ToArray()
        Assert.ArraysEqual(taken, [1, 2])
    }

    OrderBy_SortsElements() {
        unsorted := [4, 3, -6, 4, 10, 23, 1, 2]
        sorted := Query(unsorted).OrderBy((l, r) => l - r).ToArray()

        Assert.ArraysEqual(sorted, [-6, 1, 2, 3, 4, 4, 10, 23])
    }

    Reverse_ReversesElements() {
        reversed := Query.Range(1, 5).Reverse().ToArray()
        Assert.ArraysEqual(reversed, [5, 4, 3, 2, 1])
    }

    Chunk_ChunksElements() {
        chunked := Query.Range(1, 14)
            .Chunk(4)
            .ToArray()
        Assert.ArraysEqual(chunked, [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14]])
    }

    Max_WithNumericValues_ReturnsMax() {
        max := Query.Range(1, 10).Max()
        Assert.Equals(max, 10)
    }

    MaxBy_WithComparator_ReturnsMax() {
        nums := [1, 2, 3, 4, "ooglyboogly", 5, 6]
        max := Query(nums).MaxBy((v) => IsNumber(v) ? v : -1)

        Assert.Equals(max, 6)
    }

    MinMaxBy_WithSelector_ReturnsElement() {
        words := ["The", "Quick", "Brown", "Fox", "Jumped", "Over", "The", "Lazy", "Dog"]
        longest := Query(words).MaxBy(word => StrLen(word))
        shortest := Query(words).MinBy(word => StrLen(word))

        Assert.IsType(longest, String)
        Assert.Equals(longest, "Jumped")
        Assert.IsType(shortest, String)
        Assert.Equals(shortest, "The")
    }

    GroupBy_GroupsElements() {
        toGroup := Query.Range(0, 100).Select(n => {a: Round(n / 10), b: n})
        grouped := Query(toGroup)
            .GroupBy(v => v.a)
            .Select((key, group) => (key ": " group.length))  ; GroupBy yields two elements
            .ToArray()

        Assert.ArraysEqual(grouped, ["0: 5", "1: 10", "2: 10", "3: 10", "4: 10", "5: 10", "6: 10", "7: 10", "8: 10", "9: 10", "10: 6"])
    }
}