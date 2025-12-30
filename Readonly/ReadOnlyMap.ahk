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
}