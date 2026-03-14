#Requires AutoHotkey v2.0

#Include ./YUnit/Assert.ahk
#Include ./YUnit/Yunit.ahk
#Include ./YUnit/Stdout.ahk

#Include ../Text/PrefixTrieMap.ahk

class PrefixTrieMapTests {

    class Set {
        Set_WithKeyAndValue_StoresEntry() {
            trie := PrefixTrieMap()
            trie.Set("hello", 42)

            Assert.Equals(trie.Has("hello"), true)
            Assert.Equals(trie.Get("hello"), 42)
            Assert.Equals(trie.Count, 1)
        }

        Set_WithMultiplePairs_StoresAll() {
            trie := PrefixTrieMap()
            trie.Set("a", 1, "b", 2, "c", 3)

            Assert.Equals(trie.Count, 3)
            Assert.Equals(trie.Get("a"), 1)
            Assert.Equals(trie.Get("b"), 2)
            Assert.Equals(trie.Get("c"), 3)
        }

        Set_WithExistingKey_UpdatesValue() {
            trie := PrefixTrieMap()
            trie.Set("hello", 1)
            trie.Set("hello", 2)

            Assert.Equals(trie.Get("hello"), 2)
            Assert.Equals(trie.Count, 1)
        }

        Set_WithOddArgCount_ThrowsValueError() {
            trie := PrefixTrieMap()
            Assert.Throws((*) => trie.Set("hello"), ValueError)
        }

        Set_WithNonStringKey_ThrowsTypeError() {
            trie := PrefixTrieMap()
            Assert.Throws((*) => trie.Set(123, "value"), TypeError)
        }

        Set_WithEmptyStringKey_Works() {
            trie := PrefixTrieMap()
            trie.Set("", "empty")

            Assert.Equals(trie.Has(""), true)
            Assert.Equals(trie.Get(""), "empty")
        }
    }

    class Get {
        Get_WithExistingKey_ReturnsValue() {
            trie := PrefixTrieMap()
            trie.Set("hello", 42)

            Assert.Equals(trie.Get("hello"), 42)
        }

        Get_WithMissingKeyAndDefault_ReturnsDefault() {
            trie := PrefixTrieMap()
            Assert.Equals(trie.Get("missing", "fallback"), "fallback")
        }

        Get_WithMissingKeyAndNoDefault_ThrowsIndexError() {
            trie := PrefixTrieMap()
            Assert.Throws((*) => trie.Get("missing"), IndexError)
        }

        Get_WithPrefixOnly_ThrowsIndexError() {
            trie := PrefixTrieMap()
            trie.Set("Testing", 1)

            Assert.Throws((*) => trie.Get("Tes"), IndexError)
        }

        Get_WithNonString_ThrowsTypeError() {
            trie := PrefixTrieMap()
            Assert.Throws((*) => trie.Get(1), TypeError)
        }
    }
    
    class Has {
        Has_WithExistingKey_ReturnsTrue() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Tester", 2, "Testing", 3)

            Assert.Equals(trie.Has("Test"), true)
            Assert.Equals(trie.Has("Tester"), true)
            Assert.Equals(trie.Has("Testing"), true)
        }

        Has_WithNonexistentKey_ReturnsFalse() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1)

            Assert.Equals(trie.Has("NotInTrie"), false)
        }

        Has_WithPrefixOnly_ReturnsFalse() {
            trie := PrefixTrieMap()
            trie.Set("Testing", 1)

            Assert.Equals(trie.Has("Tes"), false)
        }

        Has_CaseInsensitive_ReturnsTrue() {
            trie := PrefixTrieMap()
            trie.CaseSense := false
            trie.Set("Test", 1)

            Assert.Equals(trie.Has("test"), true)
            Assert.Equals(trie.Has("TEST"), true)
        }

        Has_WithNonString_ThrowsTypeError() {
            trie := PrefixTrieMap()
            Assert.Throws((*) => trie.Has(1), TypeError)
        }

        Has_WithEmptyTrie_ReturnsFalse() {
            trie := PrefixTrieMap()
            Assert.Equals(trie.Has("Test"), false)
        }
    }

    class IsPrefix {
        IsPrefix_WithExactKey_Returns2() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Tester", 2)

            Assert.Equals(trie.IsPrefix("Test"), 2)
            Assert.Equals(trie.IsPrefix("Tester"), 2)
        }

        IsPrefix_WithPrefixOnly_Returns1() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Tester", 2)

            Assert.Equals(trie.IsPrefix("T"), 1)
            Assert.Equals(trie.IsPrefix("Tes"), 1)
            Assert.Equals(trie.IsPrefix("Teste"), 1)
        }

        IsPrefix_WithNoMatch_Returns0() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1)

            Assert.Equals(trie.IsPrefix("nonsense"), 0)
        }

        IsPrefix_WithEmptyTrie_ReturnsFalse() {
            trie := PrefixTrieMap()
            Assert.Equals(trie.IsPrefix("Test"), false)
        }
    }

    class __Item {
        Item_Get_WithExistingKey_ReturnsValue() {
            trie := PrefixTrieMap()
            trie.Set("hello", 99)

            Assert.Equals(trie["hello"], 99)
        }

        Item_Get_WithMissingKey_ThrowsIndexError() {
            trie := PrefixTrieMap()
            Assert.Throws((*) => trie["missing"], IndexError)
        }

        Item_Set_StoresValue() {
            trie := PrefixTrieMap()
            trie["hello"] := 42

            Assert.Equals(trie["hello"], 42)
            Assert.Equals(trie.Count, 1)
        }

        Item_Set_OverwritesExistingValue() {
            trie := PrefixTrieMap()
            trie["hello"] := 1
            trie["hello"] := 2

            Assert.Equals(trie["hello"], 2)
            Assert.Equals(trie.Count, 1)
        }
    }

    class Delete {
        Delete_WithExistingKey_RemovesEntry() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Tester", 2)

            trie.Delete("Tester")

            Assert.Equals(trie.Has("Tester"), false)
            Assert.Equals(trie.Has("Test"), true)
            Assert.Equals(trie.Count, 1)
        }

        Delete_PrunesBranches() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Tester", 2)

            trie.Delete("Tester")

            Assert.Equals(trie.IsPrefix("Teste"), false)
            Assert.Equals(trie.Has("Test"), true)
        }

        Delete_CaseInsensitive_RemovesEntry() {
            trie := PrefixTrieMap()
            trie.CaseSense := false
            trie.Set("Test", 1, "Tester", 2)

            trie.Delete("TESTer")

            Assert.Equals(trie.Has("tester"), false)
            Assert.Equals(trie.Has("Test"), true)
        }

        Delete_ThatEmptiesTrie_DoesNotBreak() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1)
            trie.Delete("Test")

            Assert.IsType(trie._root, PrefixTrieMap.Node)
            Assert.Equals(trie._root.children.Has("T"), false)
            Assert.Equals(trie.Count, 0)
        }

        Delete_KeyThatIsPrefix_DoesNotPruneBranches() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Testing", 2)

            trie.Delete("Test")

            Assert.Equals(trie.Has("Test"), false)
            Assert.Equals(trie.IsPrefix("Test"), true)
            Assert.Equals(trie.Has("Testing"), true)
        }

        Delete_ValueIsCleared() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Testing", 2)

            trie.Delete("Test")

            Assert.Throws((*) => trie.Get("Test"), IndexError)
        }

        Delete_WithMissingKey_ThrowsIndexError() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1)

            Assert.Throws((*) => trie.Delete("NotInTrie"), IndexError)
        }

        Delete_PrefixOnly_ThrowsIndexError() {
            trie := PrefixTrieMap()
            trie.Set("Testing", 1)

            Assert.Throws((*) => trie.Delete("Tes"), IndexError)
        }

        Delete_WithEmptyTrie_ThrowsIndexError() {
            trie := PrefixTrieMap()
            Assert.Throws((*) => trie.Delete("Test"), IndexError)
        }

        Delete_WithEmptyStringKey_DeletesIt() {
            trie := PrefixTrieMap()
            trie.Set("", "empty")
            trie.Delete("")

            Assert.Equals(trie.Has(""), false)
        }
    }

    class Search {
        Search_WithMatchingPrefix_ReturnsMapOfResults() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Tester", 2, "Testing", 3, "Tennis", 4)

            result := trie.Search("Tes")

            Assert.IsType(result, Map)
            Assert.Equals(result.Count, 3)
            Assert.Equals(result["Test"], 1)
            Assert.Equals(result["Tester"], 2)
            Assert.Equals(result["Testing"], 3)
        }

        Search_CaseInsensitive_ReturnsMatches() {
            trie := PrefixTrieMap()
            trie.CaseSense := false
            trie.Set("Test", 1, "Tester", 2, "Tennis", 3)

            result := trie.Search("TES")

            Assert.Equals(result.Count, 2)
        }

        Search_WithNoMatch_ReturnsEmptyMap() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1)

            result := trie.Search("xyz")

            Assert.IsType(result, Map)
            Assert.Equals(result.Count, 0)
        }

        Search_WithEmptyString_ReturnsAll() {
            trie := PrefixTrieMap()
            trie.Set("a", 1, "b", 2)

            result := trie.Search("")

            Assert.Equals(result.Count, 2)
        }

        Search_WithEmptyTrie_ReturnsEmptyMap() {
            trie := PrefixTrieMap()

            result := trie.Search("anything")

            Assert.IsType(result, Map)
            Assert.Equals(result.Count, 0)
        }

        Search_WithNonString_ThrowsTypeError() {
            trie := PrefixTrieMap()
            Assert.Throws((*) => trie.Search(0), TypeError)
        }

        class SearchKeys {
            SearchKeys_WithMatchingPrefix_ReturnsArrayOfKeys() {
                trie := PrefixTrieMap()
                trie.Set("Test", 1, "Tester", 2, "Testing", 3, "Tennis", 4)

                result := trie.SearchKeys("Tes")

                Assert.IsType(result, Array)
                Assert.Equals(result.Length, 3)
            }

            SearchKeys_WithNoMatch_ReturnsEmptyArray() {
                trie := PrefixTrieMap()
                trie.Set("Test", 1)

                result := trie.SearchKeys("xyz")

                Assert.Equals(result.Length, 0)
            }
        }
    }

    ; === Keys / Values ===

    class Miscellaneous {
        Keys_ReturnsAllKeys() {
            trie := PrefixTrieMap()
            trie.Set("a", 1, "b", 2, "c", 3)

            keys := trie.Keys()

            Assert.Equals(keys.Length, 3)
        }

        Values_ReturnsAllValues() {
            trie := PrefixTrieMap()
            trie.Set("a", 10, "b", 20, "c", 30)

            values := trie.Values()

            Assert.Equals(values.Length, 3)
        }

        Clear_EmptiesTrie() {
            trie := PrefixTrieMap()
            trie.Set("a", 1, "b", 2)

            trie.Clear()

            Assert.Equals(trie.Count, 0)
            Assert.Equals(trie.Has("a"), false)
            Assert.Equals(trie.IsPrefix("a"), false)
        }

        Clear_WithEmptyTrie_DoesNotBreak() {
            trie := PrefixTrieMap()
            trie.Clear()

            Assert.Equals(trie.Count, 0)
        }


        CaseSense_WhenFalse_TreatsKeysAsInsensitive() {
            trie := PrefixTrieMap()
            trie.CaseSense := false
            trie.Set("Hello", 1)

            Assert.Equals(trie.Has("hello"), true)
            Assert.Equals(trie.Get("HELLO"), 1)
            Assert.Equals(trie["hElLo"], 1)
        }
    }

    class Enumeration {
        Enum_WithOneVar_EnumeratesKeys() {
            trie := PrefixTrieMap()
            trie.Set("Test", 1, "Tester", 2, "Testing", 3)

            count := 0
            for(key in trie) {
                count++
                Yunit.Assert(key == "Test" || key == "Tester" || key == "Testing",
                    "Unexpected key: " key)
            }

            Assert.Equals(count, 3)
        }

        Enum_WithTwoVars_EnumeratesKeyValuePairs() {
            trie := PrefixTrieMap()
            trie.Set("a", 1, "b", 2)

            found := Map()
            for(key, value in trie)
                found[key] := value

            Assert.MapsEqual(found, Map("a", 1, "b", 2))
        }
    }
}

if(A_ScriptName == "PrefixTrieMap.test.ahk") {
    Yunit.Use(YUnitStdOut).Test(PrefixTrieMapTests)
}