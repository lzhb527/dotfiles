function fish_easymotion_jump --description 'Jump to a word by number (easymotion style)'
    set -l buffer (commandline -b)
    set -l matches (string match --index -a -r '\S+' -- $buffer)
    if test (count $matches) -eq 0
        return 1
    end

    set -l starts
    set -l words
    for m in $matches
        set -l parts (string split ' ' -- $m)
        set -a starts $parts[1]
        set -a words (string sub -s $parts[1] -l $parts[2] -- $buffer)
    end

    set -l n (count $starts)
    if test $n -gt 100
        set n 100
    end

    set -l display
    for i in (seq 1 $n)
        set -a display "$i:$words[$i]"
    end

    printf '\n%s\n' (string join '  ' $display)

    set -l choice ''
    while true
        read -s -n 1 -P '' -l ch
        if string match -q -r '^[0-9]$' -- "$ch"
            set choice "$choice$ch"
            if test (string length -- "$choice") -ge 3
                break
            end
            if test (math -- "$choice") -gt $n
                commandline -f repaint
                return 1
            end
        else
            break
        end
    end

    if not string match -q -r '^[0-9]+$' -- "$choice"
        commandline -f repaint
        return 1
    end

    set -l num (math -- "$choice")
    if test $num -lt 1; or test $num -gt $n
        commandline -f repaint
        return 1
    end

    commandline -C (math "$starts[$num] - 1")
    commandline -f repaint
end
