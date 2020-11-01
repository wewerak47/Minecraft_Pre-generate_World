#=================================================================
# Render Grid Setup:
#=================================================================
#                                                                       |
# 4x4 of rRegion files                          |    One Region File:
#  = 128x128 Chunks                                 |     = 32x32 Chunks
#  = 2048x2048 Blocks                               |     = 512x512 Blocks
# #------##------##------##------#  |    #------#
# |      ||      ||      ||      |  |    |      |
# |      ||      ||      ||      |  |    |      |
# |      ||      ||      ||      |  |    |      |
# #------##------##------##------#  |    #------#
# #------##------##------##------#  |
# |      ||      ||      ||      |  |    With a renderdistande = 8
# |      ||      ||      ||      |  |  That's a 4x4 grid of player postions
# |      ||      ||      ||      |  |  To render one region file.
# #------##------##------##------#  |
# #------##------##------##------#  |  each tp is: viewdistance x 16 x 2 = X blocks
# |      ||      ||      ||      |  |  number of jumps/loops is: region grid x 32 = number of chunks / veiw distance = X loops
# |      ||      ||      ||      |  |
# |      ||      ||      ||      |  |  Cord 0,0 is always the center in the grid
# #------##------##------##------#  |  And we always start the render in the lower left corner
# #------##------##------##------#  |  Eg at -X -Z and work our way towards +X +Z
# |      ||      ||      ||      |  |
# |      ||      ||      ||      |  |
# |      ||      ||      ||      |  |
# #------##------##------##------#  |
 
#=================================================================
# The chunk builder script settings
#=================================================================
Remove-Variable * -ErrorAction Ignore
$regionGrid = 5 # Region file Grid: 4 = 4x4 Grid og Region files = 2048x2048 Blocks
$viewDist = 19 # View distance in chunks on the server
$tpDelay = 1 # Delay between each Teleport
$player = "wewerak47" # Define player which will be teleported. You can use @p or name.
[bool]$env:Server = $false # Will this script run on server?
$process = "Notepad" # Name of the process. On client side its usually "Java" or "Javaw". On server side its usually the commandline "cmd".
# Continue from last position
$skipRow = 0 # How many Rows in first Column the script will skip 
$skipColumn = 0 # How many Columns the script will skip 
# row = X axis
# column = Z axis
#=================================================================
function Send {
    param (
        [string]$text,
        [int]$id = [system.convert]::ToInt32($env:AppID),
        [bool]$server = [System.Convert]::ToBoolean($env:Server)
    )
    [void] [Microsoft.VisualBasic.Interaction]::AppActivate($id)
    Start-Sleep -Milliseconds 200
    if (!$server) {
        [System.Windows.Forms.SendKeys]::SendWait("t")
    }
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("$text")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{Enter}")
}
[int]$env:AppID = [int](get-process -name $process).Id
[int]$tpStart = ((-1) * ($regionGrid / 2) * 512) # Starting position
[int]$tpDist = ($viewDist * 16 * 2) # Distance between positions
[int]$totalLoops = (($regionGrid * 32) / $viewDist)  # Calc total number of player spots per rows
[int]$totalLoopsRow = $totalLoops
[int]$totalLoopsColumn = $totalLoops
$totalLoopsRow = $totalLoops - $skipRow
$totalLoopsColumn = $totalLoops - $skipColumn
[timespan]$timeEst = New-TimeSpan -Seconds (($totalLoops * $tpDelay * 5) * $totalLoopsColumn) # Calc estimated time

Add-Type -AssemblyName PresentationCore, PresentationFramework
[void] [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.MessageBox]::Show("Operation will start in 3 seconds. `n Go to game menu (Esc) and then click on OK.")
[void] [Microsoft.VisualBasic.Interaction]::AppActivate([system.convert]::ToInt32($env:AppID))
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")

Start-Sleep -Seconds 1
Send ("/say Total number of jumps " + $totalLoopsColumn * $totalLoopsRow)
Start-Sleep -Milliseconds 300
Send "/say Estimated time $timeEst"
Start-Sleep $tpDelay
$tpStartX = ($tpStart + ($skipRow * $tpDist))
$tpStartZ = ($tpStart + ($skipColumn * $tpDist))
Send "/tp $player $tpStartX 192 $tpStartZ" # Tp to last position

# Start Loop for Z-axis
$i = 0
do {
    $i ++
    # Start Loop for X-axis
    $i2 = 0
    do {
        $i2 ++
        Start-Sleep $tpDelay # Insert Delay
        Send "/tp $player {~} {~} {~} -90 20"  # Rotate 90 deg
        Start-Sleep $tpDelay # Insert Delay
        Send "/tp $player {~} {~} {~} 0 20"   # Rotate 90 deg
        Start-Sleep $tpDelay # Insert Delay
        Send "/tp $player {~} {~} {~} 90 20"   # Rotate 90 deg
        Start-Sleep $tpDelay # Insert Delay
        Send "/tp $player {~} {~} {~} 180 20"  # Rotate 90 deg
        Start-Sleep $tpDelay # Insert Delay
        Send "/tp $player {~}$tpDist {~} {~}"  # Return to beginnig of the row
        
        Start-Sleep -Milliseconds 300
        Send "/say Finished jump $i2 out of $totalLoopsRow in row" 
        Start-Sleep $tpDelay
    } 
    until ($i2 -ge $totalLoopsRow)
    if ($totalLoopsRow -ne $totalLoops) {
        $totalLoopsRow = $totalLoops    
    }
    Send "/tp $player $tpStart 192 {~}$tpDist"  # TP one row up
    Start-Sleep -Milliseconds 300
    Send "/say Finished $i column out of $totalLoopsColumn"
} 
until ($i -ge $totalLoopsColumn)
Send "/tp $player 0 200 0"
Send "All Done"


#=================================================================
# Other Buttons
#=================================================================
 
# F8::Pause # Pause Script
# F9::Reload # Reload Script
# F10::Send t/tp $player 0 200 0 { Enter }  # TP back to 0,0
 
# Esc:
# ExitApp
# Return