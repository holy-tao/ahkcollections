#Requires AutoHotkey v2.0

/**
 * An arbitrarily ordered collection of unique items. A `Set` is backed by a `Map`, so
 * uniqueness is determined by the `Map` key uniqeness algorithm - that is, for objects,
 * by identity, and for primitives by value.
 */
class Set {

    /**
     * Whether the Set should consider string items case-sensitively
     */
    caseSense {
        get => this._Map.CaseSense
        set => this._map.CaseSense := value
    }

    count => this._Map.Count

    __New(items*) {
        this._Map := Map()
        for item in items
            this._Map[item] := ""
    }

    __Enum(vars) {
        if vars != 1
            throw ValueError("Sets can only be enumerated with 1 variable")

        return this._Map.__Enum(1)
    }

    /**
     * Insert an item into the Set
     * 
     * @param {Any} item the item to insert 
     * @returns {Integer} 1 if the item was inserted, 0 if it was already present
     */
    Insert(item) {
        if this.Has(item)
            return false

        this._Map[item] := ""
        return true
    }

    /**
     * Removes an item from the Set
     * 
     * @param {Any} item the item to remove 
     * @returns {Void} 
     */
    Remove(item) => this._Map.Delete(item)

    /**
     * Check if the Set contains an item
     * @param {Any} item the item to check 
     * @returns {Integer} 1 if the item is in the set, 0 if not
     */
    Has(item) => this._Map.Has(item)

    /**
     * Convert the set into an array
     * @returns {Array} 
     */
    ToArray() => [this*]

    /**
     * Creates a string representation of the `Set`
     * @returns {String}
     */
    ToString() {
        str := "{ "

        for item in this {
            str .= item is String
                ? '"' item '"'
                : (item is Primitive || HasMethod(item, "ToString", 0))
                    ? String(item)
                    : Type(item) "@" Format("0x{:X}", ObjPtr(item))

            if A_Index < this.count
                str .= ", "
        }

        return str " }"
    }
}
