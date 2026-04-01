-- Open or refresh an existing browser tab on localhost:8060
-- Checks Firefox first, then Chrome, then Safari. Opens new tab if none found.

on findInFirefox()
    try
        tell application "Firefox"
            activate
            tell application "System Events"
                tell process "Firefox"
                    set frontURL to value of UI element 1 of combo box 1 of toolbar "Navigation" of first window
                    if frontURL contains "localhost:8060" then
                        keystroke "r" using command down
                        return true
                    end if
                end tell
            end tell
        end tell
    end try
    return false
end findInFirefox

on findInChrome()
    try
        tell application "Google Chrome"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t starts with "http://localhost:8060" then
                        reload t
                        return true
                    end if
                end repeat
            end repeat
        end tell
    end try
    return false
end findInChrome

on findInSafari()
    try
        tell application "Safari"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t starts with "http://localhost:8060" then
                        do JavaScript "location.reload()" in t
                        return true
                    end if
                end repeat
            end repeat
        end tell
    end try
    return false
end findInSafari

if not findInFirefox() then
    if not findInChrome() then
        if not findInSafari() then
            do shell script "open http://localhost:8060/"
        end if
    end if
end if
