#Requires AutoHotkey v2.0

#Include ../Set.ahk
#Include ./TypedCollectionUtils.ahk

/**
 * A set whose elements must be objects of a given type
 */
class TypedSet extends Set {

    /**
     * Creates a new TypedSet
     * @param {Class | Array<Class>} types One or more {@link https://www.autohotkey.com/docs/v2/lib/Class.htm classes} 
     *          to restrict elements in the array to
     * @param {Any} items array of items to initialize the set with 
     */
    __New(types, items*) {
        this._types := types is Array ? types.Clone() : Array(types)

        TypedCollectionUtils.TypeCheckAll(items, this._types*)
        super.__New(items*)
    }

    Insert(item) {
        TypedCollectionUtils.TypeCheck(item, this._types*)
        super.Insert(item)
    }
}
