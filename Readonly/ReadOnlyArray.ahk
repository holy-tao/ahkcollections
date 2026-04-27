#Requires AutoHotkey v2.0

#Include ReadOnlyError.ahk

/**
 * An {@link https://www.autohotkey.com/docs/v2/lib/Array.htm Array} whose contents cannot be modified after it is 
 * initialized
 */
class ReadOnlyArray extends Array {
    __Item[index] {
        get => super.__Item[index]
        set => ReadOnlyError.ThrowFor(this)
    }

    Push(values*) => ReadOnlyError.ThrowFor(this)
    InsertAt(index, values*) => ReadOnlyError.ThrowFor(this)

    /**
     * Create a read-only clone of `arr`
     * 
     * @param {Array<Any>} arr array to copy 
     * @returns {ReadOnlyArray}
     */
    static From(arr) {
        if !(arr is Array)
            throw TypeError("Expected an Array but got a(n) " Type(arr), -1, arr)
        return ReadOnlyArray(arr*)
    }
}