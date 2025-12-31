#Requires AutoHotkey v2.0

/**
 * Holds shared utility methods for typed collections
 */
class TypedCollectionUtils {
    __New() {
        throw Error("TypedCollectionUtils is not instantiable", -1)
    }

    /**
     * Asserts that `item` is an instance of one of the classes in `types`
     * @param {Any} item the item to type check
     * @param {Class} types any number of classes 
     */
    static TypeCheck(item, types*){
        for(t in types) {
            if(item is t)
                return true
        }

        typeList := ""
        for(t in types){
            typeList .= t.Prototype.__Class
            if(A_index < types.Length)
                typeList .= " or "
        }

        throw TypeError(Format("Expected a(n) {1}, but got a(n) {2}", typeList, type(item)), -2, 
            (item is Primitive || HasMethod(item, "ToString", 0) ? String(item) : type(item)))
    }

    /**
     * Type checks every element in a collection against a list of classes
     * @param {Array<Any>} collection an enumerable collection of elements to check 
     * @param {Class} types any number of classes 
     */
    static TypeCheckAll(collection, types*){
        for(val in collection){
            TypedCollectionUtils.TypeCheck(val, types*)
        }
    }
}