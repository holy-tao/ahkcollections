#Requires AutoHotkey v2.0

/**
 * Thrown when a caller attempts to modify a read-only collection. `Extra` indicates the type of the
 * collection that the caller tried to modify
 */
class ReadOnlyError extends Error {

    /**
     * Throws a `ReadOnlyError` with the message "Collection is read-only" and with a `what` of -2
     * @param {Object} collection `type(collection)` is used as the error's extra
     */
    static ThrowFor(collection) {
        throw ReadOnlyError("Collection is read-only", -2, Type(collection))
    }
}