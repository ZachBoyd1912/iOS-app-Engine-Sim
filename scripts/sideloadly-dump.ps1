# Dumps Sideloadly's UI Automation tree so we can find the IPA field and the Start button.
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes

$proc = Get-Process sideloadly -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { Write-Output 'sideloadly not running'; exit 1 }

$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ProcessIdProperty, $proc.Id)
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
if (-not $win) { Write-Output "no top-level window for pid $($proc.Id)"; exit 1 }

Write-Output "WINDOW: $($win.Current.Name)  class=$($win.Current.ClassName)"
Write-Output "bounds: $($win.Current.BoundingRectangle)"

function Walk($element, $depth) {
    if ($depth -gt 6) { return }
    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    $child = $walker.GetFirstChild($element)
    while ($child) {
        $c = $child.Current
        $pad = '  ' * $depth
        Write-Output ("{0}[{1}] name='{2}' id='{3}' class='{4}' enabled={5}" -f $pad, $c.ControlType.ProgrammaticName.Replace('ControlType.', ''), $c.Name, $c.AutomationId, $c.ClassName, $c.IsEnabled)
        Walk $child ($depth + 1)
        $child = $walker.GetNextSibling($child)
    }
}

Walk $win 1
