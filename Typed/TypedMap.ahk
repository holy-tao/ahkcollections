#Requires AutoHotkey v2.0

#Include TypedCollectionUtils.ahk

/**
 * A  {@link https://www.autohotkey.com/docs/v2/lib/Map.htm Map} whose keys and values can only contain
 * instances of one or more {@link https://www.autohotkey.com/docs/v2/lib/Class.htm Classes}.
 * 
 *      m := TypedMap(Integer, String, 1, "one", 2.0, "two", 3, "three")
 */
class TypedMap extends Map {
    
    __New(TKey, TValue, values*) {
        this._TKeys := TKey is Array ? TKey.Clone() : Array(TKey)
        this._TValues := TValue is Array ? TValue.Clone() : Array(TValue)

        TypedCollectionUtils.TypeCheckAll(this._TKeys, Class)
        TypedCollectionUtils.TypeCheckAll(this._TValues, Class)

        for(value in values){
            TypedCollectionUtils.TypeCheck(value, (Mod(A_Index, 2) == 0 ? this._TValues : this._TKeys)*)
        }

        super.__New(values*)
    }

    __Item[index] {
        get {
            TypedCollectionUtils.TypeCheck(index, this._TKeys*)
            return super.__Item[index]
        }
        set {
            TypedCollectionUtils.TypeCheck(index, this._TKeys*)
            TypedCollectionUtils.TypeCheck(value, this._TValues*)

            return super.__Item[index] := value
        }
    }

    Get(key, default?) {
        TypedCollectionUtils.TypeCheck(key, this._TKeys*)
        return super.Get(key, default?)
    }

    Set(values*) {
        for(value in values){
            TypedCollectionUtils.TypeCheck(value, (Mod(A_Index, 2) == 0 ? this._TValues : this._TKeys)*)
        }

        return super.Set(values*)
    }
}