/************************************************************************
 * @description Prefix Trie implementation
 * @author Tao Beloney
 * @date 2026/01/01
 * 
 * Performance note: StrGet(StrPtr(key), ...) provides no perf benefit over
 * SubStr; in testing SubStr is actually slightly faster (~200ms faster for
 * ~240k keys, see below), though you need a truly enourmous amount of text 
 * to see any difference in practice. I tested with Project Gutenberg's copy 
 * of Moby Dick, which works out to ~240k words depending on how you split it
 ***********************************************************************/

#Requires AutoHotkey v2.0

/**
 * A data structure that allows for the efficient storage and lookup of large numbers of strings. Insertion and
 * lookup are guaranteed to finish in `O(n)` time, where `n` is the length of the inserted / searched-for string.
 */
class PrefixTrie {

    /**
     * @readonly The number of keys in the trie. Do not modify this variable.
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
     * Creates a new empty Prefix Trie
     * @param {Boolean} caseSense Whether or not the trie should be case-sensitive (default: true) 
     */
    __New() {
        this._root := PrefixTrie.Node()
    }

    /**
     * Adds zero or more new keys to the trie
     * 
     *      trie.Insert("Example")
     *      trie.Insert("Example", "Examples", "Exemplary", "Extraterrestrial")
     * 
     * @param {String} keys Zero or more keys to insert
     */
    Insert(keys*) {
        for(key in keys) {
            PrefixTrie._AssertIsString(key)
            current := this._root

            Loop(StrLen(key)) {
                char := SubStr(key, A_Index, 1) ; StrGet(StrPtr(key) + 2 * (A_Index - 1), 1)

                if(!current.children.Has(char)) {
                    current.children[char] := PrefixTrie.Node(this.caseSense)
                }

                current := current.children[char]
            }

            current.isLeaf := true
            this.Count++
        }
    }

    /**
     * Determines whether or not the trie contains a particular string. To determine whether or not the trie contains
     * strings that contain a string as a prefix, use `IsPrefix`.
     * 
     * @param {String} key The string to check 
     * @returns {Boolean} 1 if the trie contains key exactly, 0 if not
     */
    Contains(key) {
        PrefixTrie._AssertIsString(key)

        node := this._GetNode(key)
        if(node == "")
            return false

        return node.isLeaf
    }

    /**
     * Determines whether or not a string is a prefix or contained in the trie.
     * 
     * @param {String} key The string to check 
     * @returns {Boolean} 1 if key is a prefix in the trie, 2 if the trie contains key exactly, 0 otherwise
     */
    IsPrefix(key) {
        PrefixTrie._AssertIsString(key)

        node := this._GetNode(key)
        if(node == "")
            return false

        return node.isLeaf ? 2 : 1
    }

    /**
     * Deletes a key from the trie
     * @param {String} key The key to delete 
     */
    Delete(key) {
        PrefixTrie._AssertIsString(key)
        current := this._root
        nodeStack := Array({char: "", node: this._root})

        ; Step 1 - find key and delete it
        Loop(StrLen(key)) {
            char := SubStr(key, A_Index, 1)
            if(!current.children.Has(char)) {
                throw IndexError("Key not found", -1, key)
            }

            current := current.children[char]
            nodeStack.Push({char: char, node: current})
        }

        current.isLeaf := false

        ; Step 2 - backtrack and delete nodes that are both empty and not leaves
        candidate := nodeStack.Pop()
        while(nodeStack.Length > 0) {
            if(candidate.node.IsEmpty && !candidate.node.isLeaf) {
                toDelete := candidate.char
                candidate := nodeStack.Pop()
                candidate.node.children.Delete(toDelete)
            }
            else{
                ; Note a leaf or not empty, stop backtracking
                break
            }
        }

        this.Count--
    }

    /**
     * Returns all keys in the trie which start with `prefix`. If the trie does not contain `prefix`, returns
     * an empty array.
     * 
     *      ; Finds all keys in the trie that begin with "hel" - e.g. "hello", "help", "helicopter"
     *      for(key in trie.Search("hel")) {
     *          FileAppend(key "`n", "*")
     *      }
     * 
     * Searching for an empty string will return every key in the trie and is equivalent to calling `trie.Keys()`
     * 
     * @param {String} prefix The prefix to search for
     * @param {Boolean} includePrefixes Pass a truthy value to include prefixes as well as keys in the returned array
     *          (default: false)
     * @returns {Array<String>} All of the keys and optionally prefixes in the trie which start with `prefix` 
     */
    Search(prefix, includePrefixes := false) {
        PrefixTrie._AssertIsString(prefix)

        node := this._GetNode(prefix)
        if(node == "")
            return []

        return node.Traverse(prefix, includePrefixes)
    }

    /**
     * Retrieves all of the keys in the trie
     * @returns {Array<String>} An array containing all of the keys in the trie
     */
    Keys() => this._root.Traverse("", false)

    /**
     * Returns all keys and all prefixes in the trie
     */
    AllContents() => this._root.Traverse("", true)

    /**
     * Clears the trie
     */
    Clear() {
        this._root := PrefixTrie.Node(this.caseSense)
        this.Count := 0
    }

    /**
     * Supports single-argument enumeration of all the keys in the trie. To enumerate all keys matching a prefix,
     * enumerate the results of call to `Search`
     * 
     *      for(key in trie) {
     *          FileAppend(key "`n", "*")
     *      }
     */
    __Enum(enumVars) {
        if(enumVars != 1)
            throw ValueError("Enumeration is only supported with one variable", -1)

        return this._root.Traverse("", false).__Enum(1)
    }

    /**
     * Syntactic sugar for `Search(prefix)`. Only supports get.
     * 
     *      ; Finds all keys in the trie that begin with "hel" - e.g. "hello", "help", "helicopter"
     *      for(key in trie["hel"]) {
     *          FileAppend(key "`n", "*")
     *      }
     * 
     * @param {String} prefix Prefix to search for 
     */
    __Item[prefix] {
        get {
            PrefixTrie._AssertIsString(prefix)
            return this.Search(prefix)
        }
    }

    /**
     * Retrieves the node for a given key, or an empty string if the key does not exist
     * @param {String} key key to get the node for
     * @returns {String | PrefixTrie.Node} The node for `key`, or an empty string if no such node exists
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
            this.children := Map()
            this.children.CaseSense := caseSense
        }

        IsEmpty => this.children.Count == 0

        Traverse(prefix, includeAll) {
            arr := []
            if(this.isLeaf || includeAll)
                arr.Push(prefix)

            for(key, node in this.children) {
                arr.Push(node.Traverse(prefix . key, includeAll)*)
            }

            return arr
        }
    }
}