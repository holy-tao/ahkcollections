#Include ../Set.ahk
#Include ./YUnit/Assert.ahk
#Include ./YUnit/Yunit.ahk

class SetTests {
    Insert_ItemNotInSet_ReturnsTrue() {
        s := Set()

        Assert.Equals(s.Insert("one"), 1)
        Assert.Equals(s.Has("one"), 1)
    }

    Insert_ItemInSet_ReturnsFalse() {
        s := Set("one", "two")

        Assert.Equals(s.Insert("one"), 0)
        Assert.ArraysEqual(s.ToArray(), ["one", "two"])
    }

    Remove_ItemInSet_RemovesIt() {
        s := Set("one", "two", "three")

        s.Remove("two")

        Assert.Equals(s.Has("two"), false)
        Assert.Equals(s.Has("one"), true)
        Assert.Equals(s.Has("three"), true)
    }

    Remove_ItemNotInSet_ThrowsUnsetItemError() {
        s := Set("one", "two", "three")

        Assert.Throws(() => s.Remove("four"), UnsetItemError)
    }

    Has_ItemInSet_ReturnsTrue() {
        s := Set("one", "two", "three")

        Assert.Equals(s.Has("two"), 1)
    }

    Has_ItemNotInSet_ReturnsFalse() {
        s := Set("one", "two", "three")

        Assert.Equals(s.Has("four"), 0)
    }

    Enum_EnumeratesAllMembers() {
        count := 0

        for item in Set(1, 2, 3, 4, 5) {
            Assert.Equals(item, A_Index)
            count++
        }

        Assert.Equals(count, 5)
    }

    ToString_ReturnsString() {
        str := Set(1, 2, 3, 4, 5).ToString()
        Assert.Equals(str, "{ 1, 2, 3, 4, 5 }")
    }
}