#Requires AutoHotkey v2.0

#Include ./YUnit/Assert.ahk

#Include ../Typed/TypedArray.ahk
#Include ../Typed/TypedMap.ahk

class TypedArrayTests {

    Constructor_WithSingleType_AcceptsValuesOfType() {
        arr := TypedArray(Number, 1, 2, 3, 4, 5.0)
    }

    Constructr_WithSingleTypeAndInvalidInput_ThrowsTypeError() {
        Assert.Throws(
            (*) => TypedArray(Integer, 1, 2, 3, 4.5, 6),
            TypeError
        )
    }

    Constructor_WithMultipleTypes_AcceptsValuesOfAllTypes() {
        arr := TypedArray([String, Float], 1.0, 2.0, "4", "4.3", 3.14)
    }

    Constructr_WithMultipleTypesAndInvalidInput_ThrowsTypeError() {
        Assert.Throws(
            (*) => TypedArray([String, Float], 1.0, "2", 3, 4.5, 6),
            TypeError
        )
    }

    ItemSet_WithInvalidInput_ThrowsTypeError() {
        arr := TypedArray(String)
        Assert.Throws((*) => arr[1] := 1, TypeError)
    }

    InsertAt_WithInvalidInput_ThrowsTypeError() {
        arr := TypedArray(String)
        Assert.Throws((*) => arr.InsertAt(1, "one", 2), TypeError)
    }

    Push_WithInvalidInput_ThrowsTypeError() {
        arr := TypedArray(String)
        Assert.Throws((*) => arr.Push(1, "one", 2), TypeError)
    }
}

class TypedMapTests {
    Constructor_WithInvalidValues_ThrowsTypeError() {
        Assert.Throws(
            (*) => TypedMap(Integer, String, 1, "one", 2, "two", 3.0, "three"),
            TypeError
        )
    }

    Constructor_WithValidValues_Works() {
        tMap1 := TypedMap(Integer, String, 1, "one", 2, "two", 3, "three")
        tMap2 := TypedMap([Float, String], String, 1.2, "one point two", "2", "two", 3.14, "pi")

        Assert.Equals(tMap1[2], "two")
        Assert.Equals(tMap2[1.2], "one point two")
    }

    ItemGet_WithInvalidKeyType_ThrowsTypeError() {
        tMap := TypedMap(Integer, String)
        Assert.Throws((*) => tMap["nonsense"], TypeError)
    }

    ItemSet_WithInvalidKeyType_ThrowsTypeError() {
        tMap := TypedMap(Integer, String)
        Assert.Throws((*) => tMap["nonsense"] := "ooglyboogly", TypeError)
    }

    ItemSet_WithInvalidValueType_ThrowsTypeError() {
        tMap := TypedMap(Integer, String)
        Assert.Throws((*) => tMap[2] := 2.5, TypeError)
    }

    Get_WithInvalidKeyType_ThrowsTypeError() {
        tMap := TypedMap(Integer, String)
        Assert.Throws((*) => tMap.Get("nonsense"), TypeError)
    }

    Set_WithInvalidKeyType_ThrowsTypeError() {
        tMap := TypedMap(Integer, String)
        Assert.Throws((*) => tMap.Set("nonsense", "ooglyboogly"), TypeError)
    }

    Set_WithInvalidValueType_ThrowsTypeError() {
        tMap := TypedMap(Integer, String)
        Assert.Throws((*) => tMap.Set(2, 2), TypeError)
    }
}