<#
.SYNOPSIS
    Das FEZ Rückfall Ebenen Alarm Skript kann via Aufrufparameter gezielt Alarmvorlagen in DIVERA24/7 ansprechen.
	Anwendungsfall ist hier nur der manuelle Aufruf via FEZ Personal
   
.DESCRIPTION
    Beim Aufruf des Skriptes ist durch die angegebene 5-Ton Folge keine Adressierung von DIVERA Gruppen notwendig, da dies über die Alarmvorlagen ID gesteuert ist.
	Die gewünschten FWs oder Gruppen werden via Nummerierung aufgerufen.
    Optional sind die Parameter für Alarm Stichwort und Alarm Text.
    Sind diese Parameter nicht belegt wird als Stichwort beispielhaft:
    FW Ort - Rückfallebene
    Wehrführer FW Ort - Rückfallebene
    ausgegeben.
    Im Alarmtext steht dann immer:
    Automatischer Alarm über Rückfallebene - keine Details vorhanden
    Die Config Datei ist die selbst wie Rückfall Ebenen Skript als JSON File!

    CURL: Installation unter Windows XP
    https://www.giga.de/downloads/windows-10/tipps/curl-in-windows-installieren-und-nutzen-so-gehts/
    https://curl.haxx.se/dlwiz/?type=bin&os=Win64&flav=-&ver=-&cpu=x86_64

    JSON Convert als eigene Funktion

.PARAMETER 5TonFolge
    Dieser 1. Parameter ist zwingend immer erforderlich. Darüber wird gezielt die jeweilige zugehörige Alarmvorlage alarmiert.
.PARAMETER AlarmStichwort
    Dieser Parameter kann optional als Alarmstichwort mitgeben werden.
    Ist dieser Parameter nicht belegt wird als Stichwort beispielhaft:
    FW Ort - Rückfallebene
    Wehrführer FW Ort - Rückfallebene
    ausgegeben.
.PARAMETER AlarmTextDetail
    Dieser Parameter kann optional als Alarm Text mitgeben werden.
    Bei Nichtbefüllung steht sonst im Alarmtext immer:
    Automatischer Alarm über Rückfallebene - keine Details vorhanden    
.EXAMPLE
    Aufruf Beispiel - Mindestaufrufanforderung
    VGHUMI_Divera_Fallback_Alarm.ps1 8XXXX --> Mindestaufrufanforderung
.EXAMPLE
    Aufruf mit den beiden optionalen Parametern
    VGHUMI_Divera_Fallback_Alarm.ps1 8XXXX Ölspur --> Angabe des Stichwortes
    VGHUMI_Divera_Fallback_Alarm.ps1 8XXXX Ölspur im Ortsteils XYZ --> Weitere Details im Alarmtext
.NOTES
    Author: Andreas Müller
    Last Edit: 2020-09-01
    *   Version 1.0.0 - 01.09.2020 - initiale Version 
        


#>


param(
  [Parameter(Mandatory = $true,Position = 0,HelpMessage = "Zwingender Aufrufparameter - hier wird die aktuell ausgewerte 5-Ton Folge mitgeben")]
  [string]$5TonFolge,
  [Parameter(Mandatory = $false,Position = 1,HelpMessage = "Optionaler Aufrufparameter - hier kann das Alarmstichwort mitgeben werden")]
  [string]$AlarmStichwort,
  [Parameter(Mandatory = $false,Position = 2,HelpMessage = "Optionaler Aufrufparameter - hier kann der komplette Alarmtext mitgeben werden")]
  [string]$AlarmTextDetail
)



##############################################   Globale Parameter  ##############################################
[bool]$AlarmAusloesungScharf = $false
#[bool]$AlarmAusloesungScharf = $true
$SekundenSchlafDauer = 10
$DIVERA_Accesskey='XYZ'

#$ConfigFilePath = "C:\XXX\XXX\VG-HUMI-DIVERA-Einheiten-Gruppen.txt"
$ConfigFilePath = Get-Location
$ConfigFilePath = $ConfigFilePath.Path + '\' + 'VG-HUMI-DIVERA-Einheiten-Gruppen.txt'
# Pfad zum Ablegen der LogDateien            
#$LogPfad = "C:\XXX\XXX\Logs"
$LogPfad = Get-Location
$LogPfad = $LogPfad.Path + '\' +'FEZAlarmLogs'
If(!(test-path $LogPfad))
{
      New-Item -ItemType Directory -Force -Path $LogPfad
}
else
{
#nix zu tun 
#Write-Host 'Log bereits vorhanden'
}

If(!(test-path $ConfigFilePath))
{
Write-Host 'Config File nicht vorhanden!'
Write-Host 'Datei:VG-HUMI-DIVERA-Einheiten-Gruppen.txt muss im gleichen Verzeichnis wie Skript liegen'
Write-Host 'Skript wird abgebrochen'
exit
}


# Datum generieren. Mit diesem Beispiel wird pro Tag eine Logdatei erstellt            
$LogDatum = Get-Date -Format "yyyy-MM-dd"

###Globale Parameter Ende ###



##############################################Globale Parameter Ende##############################################

##############################################Globale Log Funktion################################################
        
function write-AlarmLogRecord
{
  param
  (
    [ValidateSet("INFO","WARNING","ERROR","DEBUG")]
    [string]$Typ = "INFO",
    [ValidateNotNullOrEmpty()]
    [string]$Text
  )

  # Generieren des Zeitstempels für die einzelnen LogZeilen            
  $TimeStamp = Get-Date -Format "[dd.MM.yyyy HH:mm:ss]"

  # Inhalt entsprechend Formatieren und zusammensetzen            
  $LogInhalt = "{0,-25}{1,-12}{2}" -f $TimeStamp,$Typ,$Text

  # Hinzufügen zum LogFile            
  Add-Content $Logfile $LogInhalt
}
###Ende Globale Log Funktion####
##############################################Globale Log Funktion Ende ###########################################


##############################################Alarm Setter Funktion################################################
function set-AlarmRueckfall
{
  param
  (
    [bool]$AlarmAusloesungScharf = $false,
    [string]$AlarmVorlage,
    [string]$GroupAlarmCode,
    [string]$AlarmStichwort,
    [string]$AlarmTextDetail

  )
  [bool]$AlarmStichwortBool = $false;
  [bool]$AlarmTextDetailBool = $false;
  if ($AlarmStichwort -ne '')
  {
    write-AlarmLogRecord -Typ INFO $AlarmStichwort
    $AlarmStichwort = 'title=' + $AlarmStichwort
    $AlarmStichwortBool = $true;
  }
  if ($AlarmTextDetail -ne '')
  {
    write-AlarmLogRecord -Typ INFO $AlarmTextDetail
    $AlarmTextDetail = 'text=' + $AlarmTextDetail
    $AlarmTextDetailBool = $true;
  }

  write-AlarmLogRecord -Typ INFO $AlarmVorlage

  if ($AlarmAusloesungScharf -eq $true)
  {

    if ($AlarmStichwortBool -eq $true -and $AlarmTextDetailBool -eq $true)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmStichwort + "&" + $AlarmTextDetail + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      #curl $AlarmAufrufUrl
      
      write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Stichwort und Textdetail!'
      write-AlarmLogRecord -Typ INFO 'Ende'
      exit
    }
    if ($AlarmStichwortBool -eq $true -and $AlarmTextDetailBool -eq $false)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmStichwort + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      #curl $AlarmAufrufUrl
           
      write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Stichwort!'
      write-AlarmLogRecord -Typ INFO 'Ende'
      exit
    }
    if ($AlarmStichwortBool -eq $false -and $AlarmTextDetailBool -eq $true)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmTextDetail + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      #curl $AlarmAufrufUrl
           
      write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Textdetail!'
      write-AlarmLogRecord -Typ INFO 'Ende'
      exit
    }
    if ($AlarmStichwortBool -eq $false -and $AlarmTextDetailBool -eq $false)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      #curl $AlarmAufrufUrl
      
      #Windows XP Web Aufruf:
      #WinXP-WebRequest $AlarmAufrufUrl

      write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst ohne weitere Details!'
      write-AlarmLogRecord -Typ INFO 'Ende'
      exit
    }
  }
  else
  {
    write-AlarmLogRecord -Typ INFO 'Alarm nur via Log Durchlauf ausgelöst da Debug an!'
    write-AlarmLogRecord -Typ INFO 'Ende'
    check-ScriptDuplicationTestSetterRemover $5TonFolge
	exit
  }

}
##############################################Alarm Setter Funktion Ende############################################


#####################################Start##########################################################################
###Check Aufruf Parameter ###
if ($5TonFolge -eq '' -or $5TonFolge.Length -ne 5)
{
  if ($5TonFolge -eq 'FEZ')
  {
      Write-Host 'Aufruf über FEZ'
      Write-Host 'weiterausbauen-funktionsaufruf-abfrage parameter etc-aufruf ortskennung zb'
      #exit
  }
  else
  {
      Write-Host 'Funktionsabbruch falscher Aufruf - die 5-Ton Folge muss zwingend mit übergeben werden!'
      exit
  }
}
else
{
  $SchleifenParameter = $5TonFolge # 5-Ton-Folge aus FMS32
  #title=EinsatzTitel&text=EinsatzText
}

###Check Aufruf Parameter Ende ###


###Check LogFileExists###
# LogFile Prüfen und erstellen falls nicht vorhanden


$CompleteLogPath = $LogPfad + "\" + $LogDatum + "_" + $5TonFolge + "_FEZAlarmLogFile.txt"

if (!(Test-Path ($CompleteLogPath)))
{
  # Erstellen des LogFiles            
  $Logfile = (New-Item ($CompleteLogPath) -ItemType File -Force).FullName

  # Überschrift für das LogFile            
  Add-Content $Logfile ("Die Alarm LogDatei wurde erstellt am $(get-date -Format "dddd dd. MMMM yyyy HH:mm:ss") Uhr`n").ToUpper()

  # Leerzeilen einfügen            
  Add-Content $Logfile "`n`n"

  # Spaltenüberschrift generieren            
  $LogInhalt = "{0,-25}{1,-12}{2}" -f "Zeitstempel","Typ","Logtext"

  # Überschrift dem Logfile hinzufügen            
  Add-Content $Logfile $LogInhalt
}
else
{
  # Falls Logfile schon vorhanden, Datei in die Variabel $Logfile aufnehmen            
  $Logfile = (Get-Item ($CompleteLogPath)).FullName

}

###Check LogFileExists Ende###

$ConfigFile = Get-Content -Encoding UTF8 $ConfigFilePath
# Anpassung als eigene Funktion wg. alter PS

$ConfigEinheitenJSON = $ConfigFile | ConvertFrom-Json

$ConfigEinheitenJSONSorted= $ConfigEinheitenJSON | Sort-Object -Property @{expression={$_.Einheiten.Einheiten-Nummern};Descending=$true} | ConvertTo-Json





