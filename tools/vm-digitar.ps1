# Digita texto na VM Nyxz-Teste, cujo teclado é ABNT2.
# O VBoxManage keyboardputstring assume layout US; símbolos são enviados por scancode.
param([Parameter(Mandatory)][string]$Texto, [switch]$Enter)

$vbm = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vm = "Nyxz-Teste"

# caractere -> scancodes (make/break) no ABNT2
$shift = @("2a"); $soltaShift = @("aa")
$mapa = @{
  '/' = @("73","f3")
  '?' = $shift + @("73","f3") + $soltaShift
  ';' = @("35","b5")
  ':' = $shift + @("35","b5") + $soltaShift
  "'" = @("29","a9")
  '"' = $shift + @("29","a9") + $soltaShift
  '[' = @("1b","9b")
  '{' = $shift + @("1b","9b") + $soltaShift
  ']' = @("2b","ab")
  '}' = $shift + @("2b","ab") + $soltaShift
  '\' = @("56","d6")
  '|' = $shift + @("56","d6") + $soltaShift
  # Teclas mortas do ABNT2: o acento sai sozinho quando seguido de espaço.
  '~' = @("28","a8","39","b9")
  '^' = $shift + @("28","a8") + $soltaShift + @("39","b9")
  '`' = $shift + @("1a","9a") + $soltaShift + @("39","b9")
}

$buffer = ""
function Despejar {
  if ($script:buffer.Length -gt 0) { & $vbm controlvm $vm keyboardputstring $script:buffer; $script:buffer = "" }
}
foreach ($c in $Texto.ToCharArray()) {
  $s = [string]$c
  if ($mapa.ContainsKey($s)) { Despejar; & $vbm controlvm $vm keyboardputscancode @($mapa[$s]) }
  else { $buffer += $s }
}
Despejar
if ($Enter) { & $vbm controlvm $vm keyboardputscancode 1c 9c }
