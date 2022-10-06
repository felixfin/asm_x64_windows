@echo off
@REM build.bat [debug|release|clean] <project_name> [exe|dll] <additional_linker_arguments>

@REM Examples:
@REM build.bat debug hello_world                    will build hello_world.asm in debug mode
@REM build.bat release goodbye_nothing              will build goodbye_nothing.asm in release mode
@REM build.bat release goodbye_nothing dll          will build goodbye_nothing.asm in release mode as a DLL instead of an exe

@REM Source: https://sonictk.github.io/asm_tutorial/#hello,worldrevisted/writingabuildscript

@REM Prerequisites:
@REM 1. Install Visual Studio 2019 (Community)
@REM 2. Install NASM for windows x64 (https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/)
@REM 3. Add NASM directory to the PATH environment variable: C:\Program Files\NASM
@REM 4. Ensure the LIB environment variable exists and contains the following values:
@REM      C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22000.0\um\x64
@REM      C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22000.0\ucrt\x64

echo Build script started executing at %time% ...



@REM ********************************************************
@REM Process command line arguments. Default is to build in release configuration.
set BuildType=%1
if "%BuildType%"=="" (set BuildType=release)

set ProjectName=%2
if "%ProjectName%"=="" (set ProjectName=hello_world)

set BuildExt=%3
if "%BuildExt%"=="" (set BuildExt=exe)

set AdditionalLinkerFlags=%4

echo Building %ProjectName% in %BuildType% configuration...



@REM ********************************************************
@REM Open "x64 Native Tools Command Prompt for VS 2019"
@REM Remark: Had to modify this
if not defined DevEnvDir (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
)



@REM ********************************************************
@REM Create directory to store all build artifacts
set BuildDir=%~dp0msbuild

if "%BuildType%"=="clean" (
    setlocal EnableDelayedExpansion
    echo Cleaning build from directory: %BuildDir%. Files will be deleted^^!
    echo Continue ^(Y/N^)^?
    set /p ConfirmCleanBuild=
    if "!ConfirmCleanBuild!"=="Y" (
        echo Removing files in %BuildDir%...
        del /s /q %BuildDir%\*.*
    )
    goto end
)

echo Building in directory: %BuildDir% ...

if not exist %BuildDir% mkdir %BuildDir%
pushd %BuildDir%



@REM ********************************************************
@REM Prepare compilation
set EntryPoint="%~dp0%ProjectName%.asm"

set IntermediateObj=%BuildDir%\%ProjectName%.obj
set OutBin=%BuildDir%\%ProjectName%.%BuildExt%

set CommonCompilerFlags=-f win64 -I%~dp0 -l "%BuildDir%\%ProjectName%.lst"
set DebugCompilerFlags=-gcv8



@REM ********************************************************
@REM Prepare linker
if "%BuildExt%"=="exe" (
    set BinLinkerFlagsMSVC=/subsystem:console /entry:main
) else (
    set BinLinkerFlagsMSVC=/dll
)

@REM This was not part of the original tutorial ->
if not defined LIB (
    setx LIB "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22000.0\um\x64;C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22000.0\ucrt\x64"
)
@REM <-

set CommonLinkerFlagsMSVC=%BinLinkerFlagsMSVC% /defaultlib:ucrt.lib /defaultlib:msvcrt.lib /defaultlib:legacy_stdio_definitions.lib /defaultlib:Kernel32.lib /defaultlib:Shell32.lib /nologo /incremental:no
set DebugLinkerFlagsMSVC=/opt:noref /debug /pdb:"%BuildDir%\%ProjectName%.pdb"
set ReleaseLinkerFlagsMSVC=/opt:ref



@REM ********************************************************
@REM Prepare compilation and linker flags depending on build type
if "%BuildType%"=="debug" (
    set CompileCommand=nasm %CommonCompilerFlags% %DebugCompilerFlags% -o "%IntermediateObj%" %EntryPoint%
    set LinkCommand=link "%IntermediateObj%" %CommonLinkerFlagsMSVC% %DebugLinkerFlagsMSVC% %AdditionalLinkerFlags% /out:"%OutBin%"
) else (
    set CompileCommand=nasm %CommonCompilerFlags% -o "%IntermediateObj%" %EntryPoint%
    set LinkCommand=link "%IntermediateObj%" %CommonLinkerFlagsMSVC%  %ReleaseLinkerFlagsMSVC% %AdditionalLinkerFlags% /out:"%OutBin%"
)



@REM ********************************************************
@REM Compilation
echo.
echo Compiling (command follows below)...
echo %CompileCommand%

%CompileCommand%

if %errorlevel% neq 0 goto error



@REM ********************************************************
@REM Linking
echo.
echo Linking (command follows below)...
echo %LinkCommand%

%LinkCommand%

if %errorlevel% neq 0 goto error
if %errorlevel% == 0 goto success



@REM ********************************************************
@REM End of program
:error
echo.
echo ***************************************
echo *      !!! An error occurred!!!       *
echo ***************************************
goto end


:success
echo.
echo ***************************************
echo *    Build completed successfully!    *
echo ***************************************

@REM added this for convenience ->
if %BuildExt%==exe (
    echo Run the program...
		%OutBin%
)
@REM <-

goto end


:end
echo.
echo Build script finished execution at %time%.
popd
exit /b %errorlevel%