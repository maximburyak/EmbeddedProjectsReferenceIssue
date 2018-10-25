
function BuildEmbeddedNuget ($projectDir, $outDir, $serverSrcDir) {
    $EMBEDDED_SRC_DIR = [io.path]::combine($projectDir, "LibraryWithEmbeddedProject")
    
    $EMBEDDED_NUSPEC = [io.path]::combine($outDir, "LibraryWithEmbeddedProject", "LibraryWithEmbeddedProject.nuspec")
    $EMBEDDED_OUT_DIR = [io.path]::combine($outDir, "LibraryWithEmbeddedProject")
    $EMBEDDED_SERVER_OUT_DIR = [io.path]::combine($EMBEDDED_OUT_DIR, "contentFiles", "any", "any")
    
    $NETSTANDARD_TARGET = "netstandard2.0"
    $NET461_TARGET = "net461"
    
    $EMBEDDED_LIB_OUT_DIR_NETSTANDARD = [io.path]::combine($EMBEDDED_OUT_DIR, "lib", "$NETSTANDARD_TARGET")
    $EMBEDDED_LIB_OUT_DIR_NET461 = [io.path]::combine($EMBEDDED_OUT_DIR, "lib", "$NET461_TARGET")
    
    write-host "Preparing LibraryWithEmbeddedProject NuGet package.."
    $nuspec = [io.path]::combine($EMBEDDED_SRC_DIR, "LibraryWithEmbeddedProject.nuspec.template")
    & New-Item -ItemType Directory -Path $EMBEDDED_SERVER_OUT_DIR -Force
    & New-Item -ItemType Directory -Path $EMBEDDED_LIB_OUT_DIR_NETSTANDARD -Force
    & New-Item -ItemType Directory -Path $EMBEDDED_LIB_OUT_DIR_NET461 -Force

    Copy-Item $nuspec -Destination $EMBEDDED_NUSPEC

    $embeddedCsproj = Join-Path -Path $EMBEDDED_SRC_DIR -ChildPath "LibraryWithEmbeddedProject.csproj";
    
    BuildEmbedded $embeddedCsproj $EMBEDDED_LIB_OUT_DIR_NETSTANDARD $NETSTANDARD_TARGET
    Remove-Item $(Join-Path $EMBEDDED_LIB_OUT_DIR_NETSTANDARD -ChildPath "*") -Exclude "LibraryWithEmbeddedProject.dll"
    
    BuildEmbedded $embeddedCsproj $EMBEDDED_LIB_OUT_DIR_NET461 $NET461_TARGET
    Remove-Item $(Join-Path $EMBEDDED_LIB_OUT_DIR_NET461 -ChildPath "*") -Exclude "LibraryWithEmbeddedProject.dll"

    BuildApp $SERVER_SRC_DIR $EMBEDDED_SERVER_OUT_DIR 
    $tempServerDir = Join-Path $EMBEDDED_SERVER_OUT_DIR -ChildPath "App"
    $serverDir = Join-Path $EMBEDDED_SERVER_OUT_DIR -ChildPath "EmbeddedApp"
    Write-Host "Move $tempServerDir -> $serverDir"
    Rename-Item $tempServerDir -NewName "EmbeddedApp"     

    try {
        Push-Location $EMBEDDED_OUT_DIR
        & ../../nuget.exe pack .\LibraryWithEmbeddedProject.nuspec
        CheckLastExitCode
    } finally {
        Pop-Location
    }

    write-host "LibraryWithEmbeddedProject NuGet package in $OUT_DIR\LibraryWithEmbeddedProject.nupkg."
}

function BuildApp ( $srcDir, $outDir) {

    if ($target) {
        write-host "Building App for $($target.Name)..."
    } else {
        write-host "Building App no specific target..."
    }

    $command = "dotnet" 
    $commandArgs = @( "publish" )

    $output = [io.path]::combine($outDir, "App");
    $quotedOutput = '"' + $output + '"'
    $commandArgs += @( "--output", $quotedOutput )

    $configuration =  'Release'
    $commandArgs += @( "--configuration", $configuration )
    $commandArgs += '"' + $srcDir + '"'
    $commandArgs += '/p:SourceLinkCreate=true'

    write-host -ForegroundColor Cyan "Publish server: $command $commandArgs"
    Invoke-Expression -Command "$command $commandArgs"
    CheckLastExitCode
}



function BuildEmbedded ( $srcDir, $outDir, $framework) {
    write-host "Building Embedded..."
    & dotnet build --no-incremental `
        --output $outDir `
        --framework $framework `
        --configuration "Release" $srcDir;
    CheckLastExitCode
}

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    Split-Path $Invocation.MyCommand.Path;
}

function CheckLastExitCode {
    param ([int[]]$SuccessCodes = @(0), [scriptblock]$CleanupScript=$null)

    if ($SuccessCodes -notcontains $LastExitCode) {
        if ($CleanupScript) {
            "Executing cleanup script: $CleanupScript"
            &$CleanupScript
        }
        $msg = @"
EXE RETURNED EXIT CODE $LastExitCode
CALLSTACK:$(Get-PSCallStack | Out-String)
"@
        throw $msg
    }
}


$PROJECT_DIR = Get-ScriptDirectory
$OUT_DIR = [io.path]::combine($PROJECT_DIR, "artifacts")
$SERVER_SRC_DIR = [io.path]::combine($PROJECT_DIR, "EmbeddedNetCoreApp")

BuildEmbeddedNuget $PROJECT_DIR $OUT_DIR $SERVER_SRC_DIR
