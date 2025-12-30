#Requires AutoHotkey v2.0

#Include ./YUnit/Assert.ahk

#Include ../Readonly/ReadOnlyArray.ahk
#Include ../Readonly/ReadOnlyMap.ahk

class ReadOnlyArrayTests {

    Call_WithItems_SetsItems() {
        arr := ReadOnlyArray(1, 2, 3, 4, 5)

        for(item in arr)
            Assert.Equals(item, A_Index)
    }

    ItemSet_Always_ThrowsReadOnlyError() {
        arr := ReadOnlyArray(1, 2, 3, 4, 5)
        Assert.Throws((*) => arr[2] := 3, ReadOnlyError)
    }

    Push_Always_ThrowsReadOnlyError() {
        arr := ReadOnlyArray(1, 2, 3, 4, 5)
        Assert.Throws((*) => arr.Push(6), ReadOnlyError)
    }

    InsertAt_Always_ThrowsReadOnlyError() {
        arr := ReadOnlyArray(1, 2, 3, 4, 5)
        Assert.Throws((*) => arr.InsertAt(1, 6), ReadOnlyError)
    }
}

class ReadOnlyMapTests {
    Call_WithItems_SetsItmes() {
        m := ReadOnlyMap(1, "1", 2, "2", 3, "3")
        for(k, v in m){
            Assert.Equals(k, A_Index)
            Assert.Equals(k, String(A_Index))
        }
    }

    ItemSet_Always_ThrowsReadOnlyError() {
        m := ReadOnlyMap(1, "1", 2, "2", 3, "3")
        Assert.Throws((*) => m[2] := "two", ReadOnlyError)
    }

    Set_Always_ThrowsReadOnlyError() {
        m := ReadOnlyMap(1, "1", 2, "2", 3, "3")
        Assert.Throws((*) => m.Set(2, "two"), ReadOnlyError)
    }
}