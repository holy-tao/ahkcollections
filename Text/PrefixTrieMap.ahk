/************************************************************************
 * @description A Map implementation backed by a prefix trie, supporting
 *              efficient prefix-based search in addition to standard
 *              Map operations.
 * @author Tao Beloney
 * @date 2026/01/01
 *
 * Performance note: StrGet(StrPtr(key), ...) provides no perf benefit over
 * SubStr; in testing SubStr is actually slightly faster (~200ms faster for
 * ~240k keys, see below), though you need a truly enourmous amount of text
 * to see any difference in practice. I tested with Project Gutenberg's copy
 * of Moby Dick, which works out to ~240k words depending on how you split it
 **********************************************************************/

#Requires AutoHotkey v2.0

/**
 * A data structure that allows for the efficient storage and lookup of key-value pairs indexed by strings,
 * with support for prefix-based searching.
 */
class PrefixTrieMap {

    /**
     * @readonly The number of key-value pairs in the trie. Do not modify this variable.
     * @type {Integer}
     */
    Count := 0

    /**
     * Whether or not the trie should be case-sensitive. True by default. Attempting to change this value on a
     * non-empty trie is an error
     * @type {Boolean}
     */
    CaseSense {
        set => this._root.children.CaseSense := value
        get => this._root.children.CaseSense
    }

    /**
     * Creates a new empty PrefixTrieMap
     */
    __New() {
        this._root := PrefixTrieMap.Node()
    }

    /**
     * Sets one or more key-value pairs in the trie. Accepts variadic key-value pairs,
     * following the same convention as AHK's built-in Map.Set().
     *
     *      trie.Set("hello", 1)
     *      trie.Set("hello", 1, "help", 2, "world", 3)
     *
     * @param {Any} args Alternating key, value pairs
     * @throws {ValueError} If an odd number of arguments is provided
     * @throws {TypeError} If any key is not a String
     */
    Set(args*) {
        if(Mod(args.Length, 2) != 0)
            throw ValueError("Set requires an even number of arguments (key-value pairs)", -1)

        Loop(args.Length // 2) {
            key := args[A_Index * 2 - 1]
            value := args[A_Index * 2]

            PrefixTrieMap._AssertIsString(key)
            current := this._root

            Loop(StrLen(key)) {
                char := SubStr(key, A_Index, 1)

                if(!current.children.Has(char)) {
                    current.children[char] := PrefixTrieMap.Node(this.CaseSense)
                }

                current := current.children[char]
            }

            if(!current.isLeaf)
                this.Count++

            current.isLeaf := true
            current.value := value
        }
    }

    /**
     * Retrieves the value associated with a key.
     *
     * @param {String} key The key to look up
     * @param {Any} default Optional default value to return if the key is not found.
     *        If omitted and the key is not found, throws an IndexError.
     * @returns {Any} The value associated with the key
     * @throws {IndexError} If the key is not found and no default is provided
     */
    Get(key, default?) {
        PrefixTrieMap._AssertIsString(key)

        node := this._GetNode(key)
        if(node == "" || !node.isLeaf) {
            if(IsSet(default))
                return default
            throw IndexError("Key not found", -1, key)
        }

        return node.value
    }

    /**
     * Determines whether or not the trie contains a particular key.
     *
     * @param {String} key The string to check
     * @returns {Boolean} true if the trie contains key exactly, false if not
     */
    Has(key) {
        PrefixTrieMap._AssertIsString(key)

        node := this._GetNode(key)
        if(node == "")
            return false

        return node.isLeaf
    }

    /**
     * Determines whether or not a string is a prefix or contained in the trie.
     *
     * @param {String} key The string to check
     * @returns {Integer} 1 if key is a prefix in the trie, 2 if the trie contains key exactly, 0 otherwise
     */
    IsPrefix(key) {
        PrefixTrieMap._AssertIsString(key)

        node := this._GetNode(key)
        if(node == "")
            return false

        return node.isLeaf ? 2 : 1
    }

    /**
     * Deletes a key-value pair from the trie and prunes empty branches.
     * @param {String} key The key to delete
     * @throws {IndexError} If the key is not found
     */
    Delete(key) {
        PrefixTrieMap._AssertIsString(key)
        current := this._root
        nodeStack := Array({char: "", node: this._root})

        ; Step 1 - find key
        Loop(StrLen(key)) {
            char := SubStr(key, A_Index, 1)
            if(!current.children.Has(char)) {
                throw IndexError("Key not found", -1, key)
            }

            current := current.children[char]
            nodeStack.Push({char: char, node: current})
        }

        if(!current.isLeaf)
            throw IndexError("Key not found", -1, key)

        ; Step 2 - clear the leaf
        current.isLeaf := false
        current.value := ""

        ; Step 3 - backtrack and delete nodes that are both empty and not leaves
        candidate := nodeStack.Pop()
        while(nodeStack.Length > 0) {
            if(candidate.node.IsEmpty && !candidate.node.isLeaf) {
                toDelete := candidate.char
                candidate := nodeStack.Pop()
                candidate.node.children.Delete(toDelete)
            }
            else{
                ; Node is a leaf or not empty, stop backtracking
                break
            }
        }

        this.Count--
    }

    /**
     * Returns all key-value pairs whose keys start with `prefix` as a Map.
     *
     *      for(key, value in trie.Search("hel")) {
     *          FileAppend(key ": " value "`n", "*")
     *      }
     *
     * Searching for an empty string will return every entry and is equivalent to enumerating the whole trie.
     *
     * @param {String} prefix The prefix to search for
     * @param {Boolean} includePrefixes Pass a truthy value to include intermediate prefix nodes (default: false)
     * @returns {Map} A Map of matching key => value pairs
     */
    Search(prefix, includePrefixes := false) {
        PrefixTrieMap._AssertIsString(prefix)

        node := this._GetNode(prefix)
        if(node == "")
            return Map()

        return node.Traverse(prefix, includePrefixes)
    }

    /**
     * Returns all keys that start with the given prefix as an Array.
     *
     * @param {String} prefix The prefix to search for
     * @returns {Array<String>} Array of matching keys
     */
    SearchKeys(prefix) {
        PrefixTrieMap._AssertIsString(prefix)

        node := this._GetNode(prefix)
        if(node == "")
            return []

        return node.TraverseKeys(prefix)
    }

    /**
     * Retrieves all of the keys in the trie
     * @returns {Array<String>} An array containing all of the keys in the trie
     */
    Keys() => this._root.TraverseKeys("")

    /**
     * Retrieves all of the values in the trie
     * @returns {Array} An array containing all of the values in the trie
     */
    Values() => this._root.TraverseValues()

    /**
     * Returns all keys (both leaf and intermediate prefix nodes) and their values as a Map.
     * Intermediate nodes have an empty string as their value.
     * @returns {Map}
     */
    AllContents() => this._root.Traverse("", true)

    /**
     * Clears the trie
     */
    Clear() {
        this._root := PrefixTrieMap.Node(this.CaseSense)
        this.Count := 0
    }

    /**
     * Supports enumeration of entries in the trie.
     *
     *      ; 1-variable: enumerates keys
     *      for(key in trie) {
     *          FileAppend(key "`n", "*")
     *      }
     *
     *      ; 2-variable: enumerates key-value pairs
     *      for(key, value in trie) {
     *          FileAppend(key ": " value "`n", "*")
     *      }
     */
    __Enum(enumVars) {
        if(enumVars == 1)
            return this._root.TraverseKeys("").__Enum(1)
        else if(enumVars == 2)
            return this._root.Traverse("", false).__Enum(2)
        else
            throw ValueError("Enumeration supports 1 or 2 variables", -1)
    }

    /**
     * Gets or sets the value associated with a specific key.
     *
     *      trie["hello"] := 42        ; Set
     *      val := trie["hello"]       ; Get (throws IndexError if not found)
     *
     * @param {String} key The key to get or set
     * @throws {IndexError} On get, if the key does not exist
     */
    __Item[key] {
        get {
            PrefixTrieMap._AssertIsString(key)
            node := this._GetNode(key)
            if(node == "" || !node.isLeaf)
                throw IndexError("Key not found", -1, key)
            return node.value
        }
        set {
            this.Set(key, value)
        }
    }

    /**
     * Retrieves the node for a given key, or an empty string if the key does not exist
     * @param {String} key key to get the node for
     * @returns {String | PrefixTrieMap.Node} The node for `key`, or an empty string if no such node exists
     */
    _GetNode(key) {
        current := this._root

        Loop(StrLen(key)) {
            char := SubStr(key, A_Index, 1)

            if(!current.children.Has(char)) {
                return ""
            }

            current := current.children[char]
        }

        return current
    }

    /**
     * Throw a `TypeError` if `val` isn't a string
     * @param {Any} val the value to check
     */
    static _AssertIsString(val) {
        if(!(val is String))
            throw TypeError("Expected a String but got a(n) " Type(val), -2, val)
    }

    /**
     * A Trie node
     */
    class Node {
        __New(caseSense := false) {
            this.isLeaf := false
            this.value := ""
            this.children := Map()
            this.children.CaseSense := caseSense
        }

        IsEmpty => this.children.Count == 0

        /**
         * Traverses the trie collecting key-value pairs into a Map.
         * @param {String} prefix The accumulated prefix so far
         * @param {Boolean} includeAll Whether to include non-leaf (prefix-only) nodes
         * @returns {Map} A Map of key => value pairs
         */
        Traverse(prefix, includeAll) {
            result := Map()
            result.CaseSense := this.children.CaseSense
            if(this.isLeaf || includeAll)
                result[prefix] := this.value

            for(char, node in this.children) {
                for(k, v in node.Traverse(prefix . char, includeAll))
                    result[k] := v
            }

            return result
        }

        /**
         * Traverses the trie collecting only keys into an Array.
         * @param {String} prefix The accumulated prefix so far
         * @returns {Array<String>}
         */
        TraverseKeys(prefix) {
            arr := []
            if(this.isLeaf)
                arr.Push(prefix)

            for(char, node in this.children) {
                arr.Push(node.TraverseKeys(prefix . char)*)
            }

            return arr
        }

        /**
         * Traverses the trie collecting only values into an Array.
         * @returns {Array}
         */
        TraverseValues() {
            arr := []
            if(this.isLeaf)
                arr.Push(this.value)

            for(char, node in this.children) {
                arr.Push(node.TraverseValues()*)
            }

            return arr
        }
    }
}