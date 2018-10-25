This is a repro project for a dependency resolution issue in a .net framework 4.7.2 test project referencing nuget package that unpacks .net dlls into project's subdirectory.

#Problem description
This issue reproduces when a tests project has three package references:
1) Microsoft.AspNetCore v 2.1.4
2) A test infrastructure nuget package (tested with microsoft's and xunit's)
3) A nuget package that contains embedded kestrel and as a result some other aspnetcore dlls.


#How to reproduce:

Open powershell
Go to UnitTest directory and execute "dotnet test" 
Examine error message


#Structure:


##Directories:

UnitTest - A class library that contains an xunit unit test
EmbeddedNetCoreApp - A net core app, that has reference to Microsoft.AspNetCore.Server.Kestrel.Core (v2.1.3)
LibraryWithEmbeddedProject -  A Class Library, that is compiled into a nuget package, during package assembly, we embed EmbeddedNetCoreApp into this project's package
Artifacts - nuget package publishing result

##Files:

buildEmbedded.ps1 - a script resposible of the "LibraryWithEmbeddedProject" nuget package generation, it embeds the "EmbeddedNetCoreApp" binaries inside the nuget package, as a resource

#Issue's origin
Original discussion of the issue is a complaing about RavenDB's client that tried referencing in a .net framework 4.7.2 project RavenDBEmbedded, aspnetcore and a test framework.
RavenDB's embedded nuget package contains ready to run ravendb server dlls, alongside with aspnetcore dlls, that came with nuget packages like kestrel.

: https://groups.google.com/forum/#!searchin/ravendb/Problem$20with$20XUnit$20$2B$20RavenDB.TestDriver$20$2B$20Microsoft.AspNetCore%7Csort:date/ravendb/aFMsFrilpxI/1sC0j4sQCAAJ
