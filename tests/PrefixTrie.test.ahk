#Requires AutoHotkey v2.0

#Include ./YUnit/Assert.ahk
#Include ./YUnit/Yunit.ahk
#Include ./YUnit/Stdout.ahk

#Include ../Text/PrefixTrie.ahk

class PrefixTrieTests {
    Contains_WithStringInTrie_ReturnsTrue() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")

        Assert.Equals(trie.Contains("Test"), true)
        Assert.Equals(trie.Contains("Tester"), true)
        Assert.Equals(trie.Contains("Testing"), true)
    }

    Insert_WithNonString_ThrowsTypeError() {
        trie := PrefixTrie()
        Assert.Throws((*) => trie.Insert(1), TypeError)
    }

    Insert_WithEmptyString_InsertsEmptyString() {
        trie := PrefixTrie()
        trie.Insert("")

        Assert.Equals(trie.Contains(""), true)
    }

    Contains_CaseInsensitveWithMatch_ReturnsTrue() {
        trie := PrefixTrie()
        trie.CaseSense := false

        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")

        Assert.Equals(trie.Contains("test"), true)
        Assert.Equals(trie.Contains("TESTER"), true)
        Assert.Equals(trie.Contains("TesTINg"), true)
    }

    Contains_WithStringNotInTrie_ReturnsFalse() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")

        Assert.Equals(trie.Contains("NotInTrie"), false)
        Assert.Equals(trie.Contains("Testingg"), false)
    }

    Contains_WithPrefix_ReturnsFalse() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")

        Assert.Equals(trie.Contains("Tes"), false)
        Assert.Equals(trie.Contains("Teste"), false)
        Assert.Equals(trie.Contains("Testin"), false)
    }

    Contains_WithNonString_ThrowsTypeError() {
        trie := PrefixTrie()
        Assert.Throws((*) => trie.Contains(1), TypeError)
    }

    Contains_WithEmptyTrie_ReturnsFalse() {
        trie := PrefixTrie()
        Assert.Equals(trie.Contains("Test"), false)
    }

    IsPrefix_WithStringNotInTrie_ReturnsFalse() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")

        Assert.Equals(trie.IsPrefix("nonsense"), 0)
    }

    IsPrefix_WithStringInTrie_Returns2() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")

        Assert.Equals(trie.IsPrefix("Test"), 2)
        Assert.Equals(trie.IsPrefix("Tester"), 2)
    }

    IsPrefix_WithPrefixInTrie_Returns1() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")

        Assert.Equals(trie.IsPrefix("T"), 1)
        Assert.Equals(trie.IsPrefix("Tes"), 1)
        Assert.Equals(trie.IsPrefix("Teste"), 1)
    }

    IsPrefix_WithEmptyTrie_ReturnsFalse() {
        trie := PrefixTrie()
        Assert.Equals(trie.IsPrefix("Test"), false)
    }

    Delete_WithItemInTrie_RemovesItAndPrunesBranches() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")

        trie.Delete("Tester")

        Assert.Equals(trie.Contains("Tester"), false)
        Assert.Equals(trie.IsPrefix("Tester"), false)
        Assert.Equals(trie.IsPrefix("Teste"), false)
        Assert.Equals(trie.Contains("Test"), true)
    }

    
    Delete_CaseInsensitiveWithItemInTrie_RemovesItAndPrunesBranches() {
        trie := PrefixTrie()
        trie.CaseSense := false
        trie.Insert("Test")
        trie.Insert("Tester")

        trie.Delete("TESTer")

        Assert.Equals(trie.Contains("tester"), false)
        Assert.Equals(trie.IsPrefix("TESter"), false)
        Assert.Equals(trie.IsPrefix("Teste"), false)
        Assert.Equals(trie.Contains("Test"), true)
    }

    Delete_ThatEmptiesTrie_DoesNotBreakEverything() {
        trie := PrefixTrie()

        trie.Insert("Test")
        trie.Delete("Test")

        Assert.IsType(trie._root, PrefixTrie.Node)
        Assert.Equals(trie._root.children.Has("T"), false)
    }

    Delete_KeyThatIsPrefix_DoesNotPruneBranches() {
        trie := PrefixTrie()

        trie.Insert("Test")
        trie.Insert("Testing")

        trie.Delete("Test")

        Assert.Equals(trie.Contains("Test"), false)
        Assert.Equals(trie.IsPrefix("Test"), true)
        Assert.Equals(trie.IsPrefix("Testin"), true)
        Assert.Equals(trie.Contains("Testing"), true)
    }

    Delete_WithKeyNotInTrie_ThrowsValueError() {
        trie := PrefixTrie()

        trie.Insert("Test")
        trie.Insert("Testing")

        Assert.Throws((*) => trie.Delete("NotInTrie"), ValueError)
    }

    Delete_WithEmptyTrie_ThrowsValueError() {
        trie := PrefixTrie()
        Assert.Throws((*) => trie.Delete("Test"), ValueError)
    }

    Delete_WithEmptyStringAndEmptyStringInTrie_DeletesIt() {
        trie := PrefixTrie()
        trie.Insert("")
        trie.Delete("")

        Assert.Equals(trie.Contains(""), false)
    }

    Enum_WithOneVar_EnumeratesKeys() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")

        for(value in trie) {
            Yunit.Assert(value == "Test" || value == "Tester" || value == "Testing", 
                "Enum found an unexpected value: " value)
        }
    }

    Enum_WithMultipleVars_ThrowsValueError() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")

        Assert.Throws(MultiEnum.Bind(trie), ValueError)

        MultiEnum(trie) {
            for(key, val in trie) {
                throw Error("How did we get here?")
            }
        }
    }

    Search_WithPrefixInTrie_FindsStrings() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")

        arr := trie.Search("Tes")
        Assert.Equals(arr.length, 3)
        for(value in arr) {
            Yunit.Assert(value == "Test" || value == "Tester" || value == "Testing", 
                "Enum found an unexpected value: " value)
        }
    }
        
    Search_CaseInsensitiveWithPrefixInTrie_FindsStrings() {
        trie := PrefixTrie()
        trie.CaseSense := false
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")

        arr := trie.Search("TES")
        Assert.Equals(arr.length, 3)
        for(value in arr) {
            Yunit.Assert(value = "Test" || value = "Tester" || value = "Testing", 
                "Enum found an unexpected value: " value)
        }
    }

    Search_WithExactMatch_ReturnsIt() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")
        
        arr := trie.Search("Test")
        Assert.Equals(arr.length, 3)
        for(value in arr) {
            Yunit.Assert(value == "Test" || value == "Tester" || value == "Testing", 
                "Enum found an unexpected value: " value)
        }
    }

    Search_WithNoMatch_ReturnsEmptyArray() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")

        arr := trie.Search("Nonsense")
        Assert.Equals(arr.length, 0)
    }

    Search_WithEmptyTrie_ReturnsEmptyArray() {
        trie := PrefixTrie()

        arr := trie.Search("Nonsense")
        Assert.Equals(arr.length, 0)
    }

    Search_WithNonStringValue_ThrowsTypeError() {
        trie := PrefixTrie()
        Assert.Throws((*) => trie.Search(0), TypeError)
    }

    Item_WithPrefixInTrie_FindsStrings() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")

        arr := trie["Tes"]
        Assert.Equals(arr.length, 3)
        for(value in arr) {
            Yunit.Assert(value == "Test" || value == "Tester" || value == "Testing", 
                "Enum found an unexpected value: " value)
        }
    }
        
    Item_CaseInsensitiveWithPrefixInTrie_FindsStrings() {
        trie := PrefixTrie()
        trie.CaseSense := false
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")

        arr := trie["TES"]
        Assert.Equals(arr.length, 3)
        for(value in arr) {
            Yunit.Assert(value = "Test" || value = "Tester" || value = "Testing", 
                "Enum found an unexpected value: " value)
        }
    }

    Item_WithExactMatch_ReturnsIt() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")
        
        arr := trie["Test"]
        Assert.Equals(arr.length, 3)
        for(value in arr) {
            Yunit.Assert(value == "Test" || value == "Tester" || value == "Testing", 
                "Enum found an unexpected value: " value)
        }
    }

    Item_WithNoMatch_ReturnsEmptyArray() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")

        arr := trie["Nonsense"]
        Assert.Equals(arr.length, 0)
    }

    Item_WithEmptyTrie_ReturnsEmptyArray() {
        trie := PrefixTrie()

        arr := trie["Nonsense"]
        Assert.Equals(arr.length, 0)
    }

    Item_WithNonStringValue_ThrowsTypeError() {
        trie := PrefixTrie()
        Assert.Throws((*) => trie[0], TypeError)
    }

    Clear_WithPopulatedTrie_ClearsTrie() {
        trie := PrefixTrie()
        trie.Insert("Test")
        trie.Insert("Tester")
        trie.Insert("Testing")
        trie.Insert("Ten")
        trie.Insert("Tennis")
        trie.Insert("Ternary")

        trie.Clear()

        Assert.Equals(trie.Count, 0)
        Assert.Equals(trie.IsPrefix("T"), false)
        Assert.Equals(trie.Contains("Tennis"), false)
    }

    Clear_WithEmptyTrie_ClearsTrie() {
        trie := PrefixTrie()
        trie.Clear()

        Assert.Equals(trie.Count, 0)
    }
}

if(A_ScriptName == "PrefixTrie.test.ahk") {
    Yunit.Use(YUnitStdOut).Test(PrefixTrieTests)
}