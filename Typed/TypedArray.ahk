#Requires AutoHotkey v2.0

#Include TypedCollectionUtils.ahk

/**
 * An {@link https://www.autohotkey.com/docs/v2/lib/Array.htm Array} that can only contain instances
 * of one or more {@link https://www.autohotkey.com/docs/v2/lib/Class.htm Classes}.
 * 
 *      arr := TypedArray(Number)
 *      arr := TypedArray(String, "one", "two", "three")
 *      arr := TypedArray([Float, String], 1.5, "0.54", 3.0, "3.14159")
 */
class TypedArray extends Array {

    /**
     * Creates a new TypedArray
     * @param {Class | Array<Class>} types One or more {@link https://www.autohotkey.com/docs/v2/lib/Class.htm classes} 
     *          to restrict elements in the array to 
     * @param {Any*} values the initial values of the array
     */
    __New(types, values*){
        this._types := types is Array ? types.Clone() : Array(types)

        TypedCollectionUtils.TypeCheckAll(this._types, Class)
        TypedCollectionUtils.TypeCheckAll(values, this._types*)

        super.__New(values*)
    }

    __Item[index] {
        get => super.__Item[index]
        set {
            TypedCollectionUtils.TypeCheck(value, this._types*)
            super.__Item[index] := value
        }
    }

    InsertAt(index, ValueN*) {
        TypedCollectionUtils.TypeCheckAll(ValueN, this._types*)

        super.InsertAt(index, ValueN*)
    }

    Push(ValueN*) {
        TypedCollectionUtils.TypeCheckAll(ValueN, this._types*)

        super.Push(ValueN*)
    }
}