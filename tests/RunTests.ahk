#Requires AutoHotkey v2.0

#Include ./YUnit/YUnit.ahk
#Include ./YUnit/ResultCounter.ahk
#Include ./YUnit/JUnit.ahk
#Include ./YUnit/Stdout.ahk

#Include ./ReadOnlyCollections.Test.Ahk
#Include ./Query.Test.Ahk

YUnit.Use(YunitResultCounter, YUnitJUnit, YUnitStdOut).Test(
	ReadOnlyArrayTests,
	ReadOnlyMapTests,
	QueryTests
)

Exit(-YunitResultCounter.failures)