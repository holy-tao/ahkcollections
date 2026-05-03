#Requires AutoHotkey v2.0

#Include ../Set.ahk
#Include ./ReadOnlyError.ahk

/**
 * A {@link Set Set} whose contents cannot be modified after it is initialized.
 */
class ReadOnlySet extends Set {
    Insert(_) => ReadOnlyError.ThrowFor(this)
    Remove(_) => ReadOnlyError.ThrowFor(this)

    /**
     * Initialize a new `ReadOnlySet` from another collection
     * 
     * @param {Array | Set} other the collection to initialize values from
     * @returns {ReadOnlySet} 
     */
    static From(other) {
        if !(other is Set) && !(other is Array)
            throw TypeError("Expected a Set or an Array, but got a(n) " type(other), -1, other)

        return ReadOnlySet(other*)
    }
}
