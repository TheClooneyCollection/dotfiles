function give_xcode_all_cpus
    defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks (sysctl -n hw.ncpu)
end

function dont_give_xcode_all_cpus
    defaults delete com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks
end

function how_many_cpus_xcode_use
    set CPUs (sysctl -n hw.ncpu)
    echo "You have $CPUs CPUs"
    set Xcode_has_CPUs (defaults read com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 2>/dev/null)
    if test $status -ne 0
        echo "Xcode is on default setting"
    else
        echo "Xcode uses $Xcode_has_CPUs CPUs"
    end
end

function enable_xcode_indexing
    defaults write com.apple.dt.XCode IDEIndexDisable 0
    defaults delete com.apple.dt.XCode IDEIndexDisable
    echo "Remember to double check with is_xcode_indexing"
end

function disable_xcode_indexing
    defaults write com.apple.dt.XCode IDEIndexDisable 1
end

function is_xcode_indexing
    defaults read com.apple.dt.XCode IDEIndexDisable 1>/dev/null 2>1

    if test $status -eq 1 # cannot find the key. Must be enabled!
        echo "Yes, it is"
        return
    end

    if test (defaults read com.apple.dt.XCode IDEIndexDisable) -eq 0
        echo "Yes, it is"
    else
        echo "NOPE"
    end
end
