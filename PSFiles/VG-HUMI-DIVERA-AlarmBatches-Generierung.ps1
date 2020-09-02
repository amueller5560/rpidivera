function ConvertTo-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    return $ps_js.Serialize($item)
}




#Config File Standard Name: VG-HUMI-DIVERA-Einheiten-Gruppen.txt

$ConfigFilePath = Get-Location
$AlarmBatchFilePath = $ConfigFilePath.Path
$ConfigFilePath = $ConfigFilePath.Path + '\' + 'VG-HUMI-DIVERA-Einheiten-Gruppen.txt'
$ConfigFile = Get-Content -Encoding UTF8 $ConfigFilePath
# Anpassung als eigene Funktion wg. alter PS
$ConfigEinheitenJSON = $ConfigFile | ConvertFrom-Json
#$ConfigEinheitenJSON = ConvertFrom-Json20 $ConfigFile

$EinheitenCounter = $ConfigEinheitenJSON.Einheiten.Count

$i=1
foreach($Einheit in $ConfigEinheitenJSON.Einheiten) {

$5TonFolge= $Einheit.SchleifenID

$AlarmBatchDateiName = -join($5TonFolge,"_",$Einheit.FeuerwehrGruppe,".bat")

$AlarmSingleBatchFilePath = $AlarmBatchFilePath + "\" + $AlarmBatchDateiName

#BeispielAufruf
#powershell -file VGHumi_Divera_Fallback_Alarm-V1-0-4.ps1 82634
#Neuer Aufruf W10
#powershell -Command "C:\Users\Divera\Desktop\Rueckfall\Ausloesung\VG-HUMI-DIVERA-Fallback-Alarm.ps1" 82010

$PSFilePath = Get-Location
$PSFilePath = $PSFilePath.Path+'\'+'VG-HUMI-DIVERA-Fallback-Alarm.ps1'
#$EinheitTest = 4711

$AlarmSingleBatchFileContent = 'powershell -Command '+'"'+$PSFilePath+'" ' + $Einheit.SchleifenID
#$AlarmSingleBatchFileContent = 'powershell -file '+'"'+$PSFilePath+'" ' + $EinheitTest
New-Item $AlarmSingleBatchFilePath

Set-Content $AlarmSingleBatchFilePath $AlarmSingleBatchFileContent
#Write-Host $i
$i = $i + 1
}
