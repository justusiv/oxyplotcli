<% Set-StrictMode -Version 3 -%>
Set-StrictMode -Version 3

function New-Oxy<% $ClassName -replace "^([^.]+\.)*", "" %> {
  [cmdletbinding()]
  param(
<% $SeriesElement.Element | foreach { -%>
    [<% $_.Class %>[]]$<% $_.Name %> = @(),
<% } -%>

<% $SeriesElement.Element | foreach { -%>
    [string]$<% $_.Name %>Name,
<% } -%>
    [Parameter(ValueFromPipeline=$true)]
    [object]$InputObject,
    [string]$StyleName,

<% ..\tools\Insert-PropertyList.ps1 -OutputType "param" -ClassName $ClassName -Indent 4 -%>

    [hashtable]$Options = @{}
  )

begin {
  $series = New-Object <% $ClassName %>

  $info = [PSCustomObject]@{
<% if ($XAxisElement -ne $null) { -%>
    XAxisTitle = "<% $XAxisElement.Name %>"
<% } else { -%>
    XAxisTitle = $null
<% } -%>
<% if ($YAxisElement -ne $null) { -%>
    YAxisTitle = "<% $YAxisElement.Name %>"
<% } else { -%>
    YAxisTitle = $null
<% } -%>
    XDataType = $null
    YDataType = $null
    BottomAxisType = "<% $BottomAxisType %>"
    LeftAxisType = "<% $LeftAxisType %>"
    RightAxisType = "<% $RightAxisType %>"
  }

<% if ($XAxisElement -ne $null) { -%>
  if ($PSBoundParameters.ContainsKey("<% $XAxisElement.Name %>Name")) { $info.XAxisTitle = $<% $XAxisElement.Name %>Name }
<% } -%>
<% if ($YAxisElement -ne $null) { -%>
  if ($PSBoundParameters.ContainsKey("<% $YAxisElement.Name %>Name")) { $info.YAxisTitle = $<% $YAxisElement.Name %>Name }
<% } -%>

<% ..\tools\Insert-PropertyList.ps1 -OutputType "assign" -ClassName $ClassName -Indent 2 -VariableName series -OptionHashName Options -%>

<% foreach ($e in $SeriesElement.Element) { -%>
  $<% $e.Name %>Data = New-Object Collections.Generic.List[<% $e.Class %>]
<% } -%>

  Set-StrictMode -Off
}

process {
  if ($InputObject -ne $null) {
<% foreach ($e in $SeriesElement.Element) { -%>
    if ($PSBoundParameters.ContainsKey("<% $e.Name %>Name")) { $<% $e.Name %>Data.Add($InputObject.$<% $e.Name %>Name) }
<% } -%>
  }
}

end {
<% foreach ($e in $SeriesElement.Element) { -%>
  if ($<% $e.Name %>Data.Count -gt 0 -and $<% $e.Name %>.Count -gt 0) { Write-Error "Data set of '<% $e.Name %>' is given in two ways"; return }
<% } -%>

<% foreach ($e in $SeriesElement.Element) { -%>
  $<% $e.Name %>Data.AddRange($<% $e.Name %>)
<% } -%>

  $dataCount = $<% $SeriesElement.Element[0].Name %>Data.Count
  for ($i = 0; $i -lt $dataCount; ++$i) {
<% foreach ($e in $SeriesElement.Element) { -%>
    if ($i -lt $<% $e.Name %>Data.Count) { $<% $e.Name %>Element = $<% $e.Name %>Data[$i] } else { $<% $e.Name %>Element = $null }
<% } -%>
    <% $SeriesElement.Cmdlet %> $series<% $SeriesElement.Element | foreach { %> $<% $_.Name %>Element<% } %>
  }

<% if ($XAxisElement -ne $null) { -%>
  if ($<% $XAxisElement.Name %>Data.Count -gt 0) { $info.XDataType = $<% $XAxisElement.Name %>Data[0].GetType() }
<% } -%>
<% if ($YAxisElement -ne $null) { -%>
  if ($<% $YAxisElement.Name %>Data.Count -gt 0) { $info.YDataType = $<% $YAxisElement.Name %>Data[0].GetType() }
<% } -%>

#  Apply-Style "<% $ClassName %>" $l $MyInvocation $StyleName

  $series | Add-Member -PassThru NoteProperty _Info $info
}
}
