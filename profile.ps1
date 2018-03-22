function s { cd .. }
function d { cd - }
set-alias ll gci
set-alias ss select-string
if(get-command less -erroraction silentlycontinue) { set-alias more less }

# Editor variable and alias.
if(!$EDITOR) { $global:EDITOR = 'c:\windows\system32\notepad.exe' }
$alias:e = $EDITOR


# Prompt stuff.
if(!$noPrompt)
{
  # Used by the prompt function.
  function global:pathComponents($path, $num)
  {
    if($path.EndsWith('\')) { return $path }
    $j = $path.Length
    for($i=0; $i -lt $num; $i++)
    {
      $j2 = $path.LastIndexOf('\', $j - 1)
      if($j2 -eq -1) { return $path }
      $j = $j2
    }
    return $path.Substring($j + 1)
  }
  
  # Better prompt.
  function global:prompt
  {
    $path = (get-location).Path
    $short = pathComponents $path $promptLen
    if ($isAdmin) { $adminText = "Administrator: " }    
    $host.UI.RawUI.WindowTitle = "Shell - $adminText$path"
    if(!$timeFormat) { "$short $ " }
    else
    {
      $time = (get-date).ToString($timeFormat)
      "$time $short $ "
    }
  }
}


# Better, UNIX-like, 'cd' command.
if (test-path alias:cd) { del alias:cd }
function cd($path)
{
  if(!$path)
  {
    cd $env:USERPROFILE
  }
  elseif($path -eq '-')
  {
    $last = $OLDPWD
    $global:OLDPWD = $PWD
    sl $last
    $last.Path
  }
  else
  {
    $global:OLDPWD = $PWD
    if ([IO.File]::Exists((Join-Path $PWD $path))) { $path = Split-Path $path }
    sl $path
    # canonicalize path (done after sl to make sl do all error checking)
    if($pwd.provider.Name -eq "FileSystem")
    { sl (getCanonicalPath($pwd.providerpath)) }
  }
}

# return a file system canonical path (with correct casing)
function getCanonicalPath($path)
{
  if($path.startswith('\\'))
  {
    $computer,$share,$path = $path.split('\', 3, [stringsplitoptions]::removeemptyentries)
    if($path)
    { $components = $path.split('\') }
    else
    { $components = @() }
    $canonical = "\\$($computer)\$($share)"
  }
  else
  {
    $canonical, $components = $path.split('\')
  }
  
  $components | % {
    $c = $_
    $dirs = gci -fo ($canonical + "\")
    foreach($name in $dirs)
    {
      if($c -eq $name) { $canonical += "\" + $name; break }
    }
  }
  return $canonical
}

# Shortcut for gci -rec -fil ... | select-string ...
function find($data, $type = 'cs', [switch]$simple, [switch]$list)
{
  gci -rec -fil "*.$type" | select-string -simple:$simple -list:$list $data
}


# Test if current account has an administrator token.
function Test-IsAdmin
{
  $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
  $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
  $prp.IsInRole($adm)
}


# Update LastWriteTime and create file if missing.
function Touch-Item($path = $(throw 'Path must be given.'))
{
  if(test-path $path) { (gi $path).LastWriteTime = get-date }
  else { sc $path $null }
}
set-alias touch touch-item


# UNIX-style which command
function which($program)
{
  @(get-command $program)[0].Definition
}

# The join-path cmdlet is, unfortunately, buggy and useless. We define a working one here.
function Join-Path($Path, $ChildPath)
{
  try
  {
    [System.IO.Path]::Combine($Path, $ChildPath)
  }
  catch
  {
    Write-Host "Joining '$Path' and '$ChildPath' failed."
    throw
  }
}

function trepunkt($optimistisk, $realistisk, $pessimistisk) {
  $vaegt = 3
  $middel = ($optimistisk + $vaegt * $realistisk + $pessimistisk) / (1 + $vaegt + 1)
  $varians = [Math]::Pow($optimistisk - $pessimistisk, 2) / [Math]::Pow(1 + $vaegt + 1, 2)
  $stdafv = [Math]::Sqrt($varians)
  $middel + $stdafv
}
