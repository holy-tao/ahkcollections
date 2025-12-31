#Requires AutoHotkey v2.0

#Include ./YUnit/YUnit.ahk
#Include ./YUnit/ResultCounter.ahk
#Include ./YUnit/JUnit.ahk
#Include ./YUnit/Stdout.ahk

#Include ./ReadOnlyCollections.Test.Ahk
#Include ./TypedCollections.Test.ahk
#Include ./Query.Test.Ahk

YUnit.Use(YunitResultCounter, YUnitJUnit, YUnitStdOut).Test(
	ReadOnlyArrayTests,
	ReadOnlyMapTests,
	TypedArrayTests,
	TypedMapTests,
	QueryTests
)

Exit(-YunitResultCounter.failures)