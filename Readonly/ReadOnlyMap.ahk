#Requires AutoHotkey v2.0

#Include ReadOnlyError.ahk

/**
 * A {@link https://www.autohotkey.com/docs/v2/lib/Map.htm Map} whose contents cannot be modified after it is
 * initialized
 */
class ReadOnlyMap extends Map {

    __Item[key]{
        get => super.__Item[key]
        set => ReadOnlyError.ThrowFor(this)
    }
    
    Set(ValueN*) => ReadOnlyError.ThrowFor(this)

    /**
     * Create a read-only copy of `other`
     * 
     * @param {Map} other the map to copy
     * @returns {ReadOnlyMap} 
     */
    static From(other) {
        if !(other is Map)
            throw TypeError("Expected a Map but got a(n) " Type(other), -1, other)

        ; Can't expand a map into key, value pairs compatible with __New
        ObjSetBase(readOnly := other.Clone(), ReadOnlyMap.Prototype)
        return readOnly
    }
}