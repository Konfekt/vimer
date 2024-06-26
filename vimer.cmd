@echo off
goto :main

rem Vimer - A convenience wrapper for gvim --remote(-tab)-silent.

rem The MIT License (MIT)
rem
rem Copyright (c) 2010-2016 Susam Pal
rem
rem Permission is hereby granted, free of charge, to any person obtaining
rem a copy of this software and associated documentation files (the
rem "Software"), to deal in the Software without restriction, including
rem without limitation the rights to use, copy, modify, merge, publish,
rem distribute, sublicense, and/or sell copies of the Software, and to
rem permit persons to whom the Software is furnished to do so, subject to
rem the following conditions:
rem
rem The above copyright notice and this permission notice shall be
rem included in all copies or substantial portions of the Software.
rem
rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
rem EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
rem MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
rem IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
rem CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
rem TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
rem SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

:main
    setlocal
    set VERSION=0.2.1-DEV
    set AUTHOR=Susam Pal
    set COPYRIGHT=Copyright (c) 2010-2016 %AUTHOR%
    set LICENSE_URL=http://susam.in/licenses/mit/
    set SUPPORT_URL=https://github.com/susam/vimer/issues
    set NAME=%~n0

    set BUF_SHORTCUT=Edit with GVim
    set TAB_SHORTCUT=Edit with GVim tab

    if "%VIM_CMD%" == "" call :find_vim

    call :parse_arguments %*

    endlocal
    goto :eof

:find_vim
    rem Check registry for GVim path.
    reg query HKLM\SOFTWARE\Vim\GVim > nul 2>&1
    IF %ERRORLEVEL% EQU 0 (
        for /f "tokens=2*" %%a in ('reg query HKLM\SOFTWARE\Vim\GVim') do set VIM_CMD="%%b"
        IF EXIST "%VIM_CMD%" goto :eof
    )
    rem Check for gvim.exe in system path.
    where /q gvim.exe
    IF NOT ERRORLEVEL 1 (
        SET VIM_CMD=gvim.exe
        goto :eof
    )
    rem Check for %EDITOR% environment variable.
    IF DEFINED EDITOR (
        IF EXIST "%EDITOR%" (
            SET VIM_CMD=%EDITOR%
            goto :eof
        ) ELSE (
            where /q %EDITOR%
            IF NOT ERRORLEVEL 1 (
                SET VIM_CMD=%EDITOR%
                goto :eof
            )
        )
    )
    goto :eof

:parse_arguments
    rem Parse options and arguments.
    if "%~1" == "-t" (
        set tab=-tab
        shift
        goto :parse_arguments
    ) else if "%~1" == "--tab" (
        set tab=-tab
        shift
        goto :parse_arguments
    ) else if "%~1" == "-s" (
        if "%~2" == "" (
            call :err Argument missing after: "%~1".
            exit /b 1
        )
        set server=%~2
        shift & shift
        goto :parse_arguments
    ) else if "%~1" == "--server" (
        if "%~2" == "" (
            call :err Argument missing after: "%~1".
            exit /b 1
        )
        set server=%~2
        shift & shift
        goto :parse_arguments
    ) else if "%~1" == "-n" (
        call :show_name
        goto :eof
    ) else if "%~1" == "--name" (
        call :show_name
        goto :eof
    ) else if "%~1" == "-w" (
        call :where_am_i
        goto :eof
    ) else if "%~1" == "--where" (
        call :where_am_i
        goto :eof
    ) else if "%~1" == "-h" (
        call :show_help
        goto :eof
    ) else if "%~1" == "--help" (
        call :show_help
        goto :eof
    ) else if "%~1" == "/?" (
        call :show_help
        goto :eof
    ) else if "%~1" == "-v" (
        call :show_version
        goto :eof
    ) else if "%~1" == "--version" (
        call :show_version
        goto :eof
    )

    rem Start GVim if no file arguments are specified.
    if "%~1" == "" (
        call :exec_vim
        goto :eof
    ) else if "%~1" == "-" (
        rem Read input from standard input if hyphen is specified.
        if not "%~2" == "" (
            call :err Too many edit arguments: "%~2".
            exit /b 1
        )
        call :exec_vim_with_stdin
        goto :eof
    )

    rem Process remaining file arguments.
    set args=
    :consume_args
        if "%~1" == "" goto :exec_vim
        set args=%args% "%~1"
        shift
        goto :consume_args

:exec_vim_with_stdin
    setlocal
    set tmp_dir=%temp%\vimer
    if not exist %tmp_dir% mkdir %tmp_dir%
    set filename=_STDIN_%random%_%date:/=-%_%time::=-%.tmp
    set filename=%filename: =_%
    set stdin_file="%tmp_dir%\%filename%"
    if exist "%stdin_file%" goto :exec_vim_with_stdin
    findstr "^" > "%stdin_file%"
    call :exec_vim "%stdin_file%"
    endlocal
    goto :eof

:exec_vim
    if "%VIM_CMD%" == "" (
        call :err Cannot find GVim.
        exit /b 1
    )
    if not "%server%" == "" set opts=%opts% --servername "%server%"
    if not "%~1" == "" set opts=%opts% --remote%tab%-silent
    QPROCESS gvim.exe >NUL
    IF %ERRORLEVEL% EQU 0 (
        if EXIST "%~f1" start /b "" %VIM_CMD% %opts% --remote%tab%-silent %*
    ) else (
        start /b "" %VIM_CMD% %opts% %*
    )
    goto :eof

:show_name
    echo %VIM_CMD%
    call :pause
    goto :eof

:where_am_i
    echo %~f0
    call :pause
    goto :eof

:err
    >&2 echo %NAME%: %*
    call :pause
    goto :eof

:show_help
    echo Usage: %NAME% [-t] [-s] [-e^|-d] [-n] [-w] [-h] [-v] [-^|FILE...]
    echo.
    echo This is a wrapper script to open files in existing GVim. If an
    echo existing instance of GVim is running, the files are opened in it,
    echo otherwise, a new GVim instance is launched. If no FILE is
    echo specified, a new GVim instance is launched.
    echo.
    echo If this script cannot find GVim, set the VIM_CMD environment
    echo variable with the command to execute GVim as its value.
    echo.
    echo Arguments:
    echo   -                  Read text from standard input.
    echo   FILE...            Read text from one or more files.
    echo.
    echo Options:
    echo   -t, --tab          Open each file in new tab.
    echo   -s, --server NAME  Open files in GVim server with specified NAME.
    echo   -n, --name         Show the name/path of GVim being used.
    echo   -w, --where        Show the path where this script is present.
    echo   -h, --help, /?     Show this help and exit.
    echo   -v, --version      Show version and exit.
    echo.
    echo Report bugs to ^<%SUPPORT_URL%^>.
    call :pause
    goto :eof

:show_version
    echo Vimer %VERSION%
    echo %COPYRIGHT%
    echo.
    echo This is free and open source software. You can use, copy, modify,
    echo merge, publish, distribute, sublicense, and/or sell copies of it,
    echo under the terms of the MIT License. You can obtain a copy of the
    echo MIT License at <%LICENSE_URL%>.
    echo.
    echo This software is provided "AS IS", WITHOUT WARRANTY OF ANY KIND,
    echo express or implied. See the MIT License for details.
    call :pause
    goto :eof

:pause
    echo %cmdcmdline% | findstr /i /c:"%~nx0" > nul && pause > nul
    goto :eof
