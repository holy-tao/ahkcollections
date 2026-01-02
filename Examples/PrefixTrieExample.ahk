/************************************************************************
 * @description Example script demonstrating the use of the Prefix Trie. Requires Stopwatch() from my fork of YUnit;
 *              run `git submodule update --init --recursive` to grab everything
 * @author Tao Beloney
 * @date 2026/01/01
 ***********************************************************************/

#Requires AutoHotkey v2.0

#Include ../Text/PrefixTrie.ahk
#Include ../tests/YUnit/Stopwatch.ahk

trie := PrefixTrie()
trie.CaseSense := true ; Chage the true to false here to make the trie case-insensitive
text := FileRead("moby-dick.txt", "UTF-8")

watch := Stopwatch()
watch.Start()
Loop Parse text, " `n`t`r", " `n`t`r" {
    trie.Insert(A_LoopField)
}
time := watch.Stop()

insertionMsg := Format("Inseted {1} words into trie in {2:.4f} seconds ({3:.4f}ms)`n", trie.Count, time, time * 1000)

window := Gui("-Resize +OwnDialogs", "Prefix Trie Example")
editCtl := window.AddEdit("-Multi vEdit w340")
editCtl.SetFont("", "Consolas")
incPrefixes := window.AddCheckbox("Checked0 vIncludePrefixes YS+4", "Include prefixes")
outputCtl := window.AddEdit("+ReadOnly +Multi w460 r20 -Border X8", "Type at least 1 character")
outputCtl.SetFont("", "Consolas")
statusBar := window.AddStatusBar("", insertionMsg)

editCtl.OnEvent("Change", UpdateOutput)
incPrefixes.OnEvent("Click", UpdateOutput)
window.OnEvent("Close", (*) => ExitApp(1))

window.Show()

UpdateOutput(*) {
    static watch := Stopwatch()

    if(StrLen(editCtl.Value) == 0){
        statusBar.SetText(insertionMsg)
        outputCtl.Value := "Type at least 1 character"
        return
    }

    ; Time the lookup
    watch.Start()
    words := trie.Search(editCtl.Value, incPrefixes.Value)
    seconds := watch.Stop()

    outputCtl.Opt("-Redraw")
    newText := "", VarSetStrCapacity(&newText, 4096)
    for(word in words) {
        newText .= (trie.CaseSense ? word : StrUpper(word)) "`n"
    }
    outputCtl.Value := newText
    outputCtl.Opt("+Redraw")

    statusBar.SetText(Format("Found {1} matche(s) for `"{2}`" in {3:.4f} seconds ({4:.4f} ms)", 
        words.length, editCtl.Value, seconds, seconds * 1000))
}