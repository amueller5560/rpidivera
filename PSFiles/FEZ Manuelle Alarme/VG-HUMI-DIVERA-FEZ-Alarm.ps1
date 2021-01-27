<#
.SYNOPSIS
    Das manueller Alarm Skript kann gezielt Gruppen/Untereinheiten in DIVERA24/7 ansprechen.
	Anwendungsfall ist hier nur der manuelle Aufruf via FEZ Personal
   
.DESCRIPTION
    Die gewünschten FWs oder Gruppen werden via Nummerierung aufgerufen. Im Hintergrund sind die benötigten RICs im Config File hinterlegt.
    Optional sind die Parameter für Alarm Stichwort und Alarm Text.
    Sind diese Parameter nicht belegt wird als Stichwort beispielhaft:
    FW Ort - Alarm über FEZ
    Wehrführer FW Ort - Alarm über FEZ
    ausgegeben.

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

.NOTES
    Author: Andreas Müller
    Last Edit: 2020-10-23
    *   Version 1.0.0 - 01.09.2020 - initiale Version 
        


#>

param(
  [Parameter(Mandatory = $false,Position = 0,HelpMessage = "Aufrufparameter für FEZ Massenalarm - hier wird die IDs der Einheiten komma separiert mitgegeben!")]
  [string]$EinheitenIDs,
  [Parameter(Mandatory = $false,Position = 1,HelpMessage = "Optionaler Aufrufparameter - hier kann das Alarmstichwort mitgeben werden")]
  [string]$AlarmStichwort,
  [Parameter(Mandatory = $false,Position = 2,HelpMessage = "Optionaler Aufrufparameter - hier kann der komplette Alarmtext mitgeben werden")]
  [string]$AlarmTextDetail
)


##############################################   Globale Parameter  ##############################################
[bool]$AlarmAusloesungScharf = $false
#[bool]$AlarmAusloesungScharf = $false
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
    [string]$AlarmStichwort,
    [string]$AlarmTextDetail

  )
  [bool]$AlarmStichwortBool = $false;
  [bool]$AlarmTextDetailBool = $false;
  if ($AlarmStichwort -ne '')
  {
    #write-AlarmLogRecord -Typ INFO $AlarmStichwort
    $AlarmStichwort = 'title=' + $AlarmStichwort
    $AlarmStichwortBool = $true;
  }
  if ($AlarmTextDetail -ne '')
  {
    #write-AlarmLogRecord -Typ INFO $AlarmTextDetail
    $AlarmTextDetail = 'text=' + $AlarmTextDetail
    $AlarmTextDetailBool = $true;
  }

  #write-AlarmLogRecord -Typ INFO $AlarmVorlage

  if ($AlarmAusloesungScharf -eq $true)
  {

    if ($AlarmStichwortBool -eq $true -and $AlarmTextDetailBool -eq $true)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmStichwort + "&" + $AlarmTextDetail + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      #curl $AlarmAufrufUrl
      
      #write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Stichwort und Textdetail!'
      #write-AlarmLogRecord -Typ INFO 'Ende'
    }
    if ($AlarmStichwortBool -eq $true -and $AlarmTextDetailBool -eq $false)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmStichwort + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      #curl $AlarmAufrufUrl
           
      #write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Stichwort!'
      #write-AlarmLogRecord -Typ INFO 'Ende'
    }
    if ($AlarmStichwortBool -eq $false -and $AlarmTextDetailBool -eq $true)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmTextDetail + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      #curl $AlarmAufrufUrl
           
      #write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Textdetail!'
      #write-AlarmLogRecord -Typ INFO 'Ende'
    }
    if ($AlarmStichwortBool -eq $false -and $AlarmTextDetailBool -eq $false)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      #curl $AlarmAufrufUrl
      
      #Windows XP Web Aufruf:
      #WinXP-WebRequest $AlarmAufrufUrl

      #write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst ohne weitere Details!'
      #write-AlarmLogRecord -Typ INFO 'Ende'
    }
  }
  else
  {
    write-AlarmLogRecord -Typ INFO 'Alarm nur via Log Durchlauf ausgelöst da Debug an!'
    #write-AlarmLogRecord -Typ INFO 'Ende'
  }

}
##############################################Alarm Setter Funktion Ende############################################


###Check Aufruf Parameter Ende ###


###Check LogFileExists###
# LogFile Prüfen und erstellen falls nicht vorhanden


$CompleteLogPath = $LogPfad + "\" + $LogDatum + "_FEZAlarmLogFile.txt"

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
$ConfigFilePath = Get-Location
$ConfigFilePath = $ConfigFilePath.Path + '\' + 'VG-HUMI-DIVERA-Einheiten-Gruppen.txt'


$ConfigFileJSON = Get-Content $ConfigFilePath | ConvertFrom-Json

$ConfigFileJSON.Einheiten = $ConfigFileJSON.Einheiten | Sort-Object EinheitenNummer

###Check LogFileExists Ende###
###Alarm FEZ Menu######
function FEZ-Menu
{
    
    param
   (
    [string]$EinheitenIDs,
    [string]$AlarmStichwort,
    [string]$AlarmTextDetail
   )
    $OutPutString ='####### ########################## #######'
    $OutPutString +='####### Manueller DIVERA FEZ Alarm #######'
    $OutPutString +='####### ########################## #######'
    
    #Write-Host ''
    #Write-Host ''
    #Write-Host '####### Manueller DIVERA FEZ Alarm #######'
    #Write-Host '####### ########################## #######'
    #Write-Host ''
    #Write-Host ''
    Write-Host $OutPutString | Out-String
    if ($AlarmStichwort -ne '')
    {
        #Write-Host 'Es wurde ein Stichwort mitgeben'
    }
    if ($AlarmTextDetail -ne '')
    {
        #Write-Host 'Es wurden weitere Details zum Alarm mitgeben!'
    }


    $AlarmStichwortEingabe = $null
    $AlarmTextDetailEingabe = $null
    $FEZAlarmEinheitenStr =$null
    $FEZAlarmEinheitenArr =$null
    $FEZAlarmEinheitenAlarmArr = $null
    $EinheitenCounter = 0
    $EinheitenFehlerCounter = 0
    $ConfigMenu= $ConfigFileJSON.Einheiten |where { $_.RelevantFEZAlarm -eq 'j' } |Select FeuerwehrGruppe ,EinheitenNummer 
    if ($EinheitenIDs -ne '')
    {
        #Write-Host 'Es wurden Einheiten beim Aufruf mitgeben diese werden nun übernommen!'
        $OutPutString ='Es wurden Einheiten beim Aufruf mitgeben diese werden nun übernommen!'
        Write-Host $OutPutString | Out-String
        $FEZAlarmEinheitenStr = $EinheitenIDs
        $FEZAlarmEinheitenArr = $FEZAlarmEinheitenStr.Split("{,}")
    }
    else
    {
        #Write-Host '####### Einheiten-Auswahl #######'
        #$OutPutString ='####### Einheiten-Auswahl #######'
        #Write-Host $OutPutString | Out-String
        $ConfigMenu| Select @{Name="Nummer der Einheit";E={$_.EinheitenNummer}},@{Name="Name der Einheit";E={$_.FeuerwehrGruppe}} | Out-String | Write-Host
        $ConfigMenuAusgabe = $ConfigMenu | Select @{Name="Nummer der Einheit";E={$_.EinheitenNummer}},@{Name="Name der Einheit";E={$_.FeuerwehrGruppe}}
        
        $FEZAlarmEinheitenStr = Read-Host -Prompt "####### Welche Einheit(en) sollen alarmiert werden?#######"
        $FEZAlarmEinheitenArr = $FEZAlarmEinheitenStr.Split("{,}")
    }

    #Write-Host 'Folgende Einheiten werden alarmiert:'
    $OutPutString = 'Folgende Einheiten werden alarmiert:'
    #Write-Host '- - - - - - - - - - - - - - - - - - -'
    $OutPutString += '- - - - - - - - - - - - - - - - - - -'
    foreach($Einzeleinheit in $FEZAlarmEinheitenArr) 
        {
            ##$u.surname
            $Einheit = $ConfigFileJSON.Einheiten.Where({$_.EinheitenNummer -eq $Einzeleinheit})
            If ($Einheit -ne $null)
            {
                $FEZAlarmEinheitenAlarmArr = $FEZAlarmEinheitenAlarmArr + $Einzeleinheit
                #Write-Host $Einheit.EinheitenNummer ' - ' $Einheit.FeuerwehrGruppe
                $OutPutString +=$Einheit.EinheitenNummer + ' - ' + $Einheit.FeuerwehrGruppe
                #Write-Host ''
                $EinheitenCounter = $EinheitenCounter + 1
            }
            else
            {
                #Write-Host 'Einheit '$Einzeleinheit' nicht gefunden nächste Einheit wird ggfs. ausgelesen!'
                $EinheitenFehlerCounter = $EinheitenFehlerCounter + 1
            }
        }
    #Write-Host '- - - - - - - - - - - - - - - - - - -'
    if($EinheitenCounter -eq 0)
    {
        Write-Host 'Keine Einheiten gefunden Programmabbruch!'
        Exit
    }
    else
    {
        #Write-Host "Es wurden insgesamt "$EinheitenCounter" Einheit(en) gefunden - "$EinheitenFehlerCounter" Einheit(en) wurden nicht gefunden werden verworfen!"
        $OutPutString += "Es wurden insgesamt "+$EinheitenCounter+" Einheit(en) gefunden - "+$EinheitenFehlerCounter+"Einheit(en) wurden nicht gefunden werden verworfen!"
        Write-Host $OutPutString | Out-String
        #Write-Host ''

    }   
    #$AlarmStichwortEingabe = Read-Host -Prompt "Bitte geben Sie das gewünschte Alarmstichwort ein!"
    if($AlarmStichwort -ne '')
    {
        #Write-Host 'Es wurde ein AlarmStichwort mitgeben. Dieses wird nun übernommen'
        Write-Host "AlarmStichwort: " $AlarmStichwort
        Write-Host ''
        $AlarmStichwortEingabe = $AlarmStichwort
    }
    else
    {
        $AlarmStichwortEingabe = 'Einsatzalarm'
    }
    if($AlarmTextDetail -ne '')
    {
        #Write-Host 'Es wurde ein Alarmtext mitgeben. Dieses wird nun übernommen'
        Write-Host "AlarmText: " $AlarmTextDetail
        Write-Host ''
        $AlarmTextDetailEingabe = $AlarmTextDetail
    }
    else
    {
         $AlarmTextDetailEingabe =  Read-Host -Prompt "Bitte geben Sie den gewünschte Alarmtext ein (optional)!"
    }
    


    Write-Host 'Sind Sie sicher, dass Sie dise Einheiten alamieren wollen?'
    $EinheitenFehlerCounter = 0
    #foreach($EinzelAlarmeinheit in $FEZAlarmEinheitenArr) 
    #    {
            ##$u.surname
    #        $Einheit = $ConfigFileJSON.Einheiten.Where({$_.EinheitenNummer -eq $EinzelAlarmeinheit})
    #        If ($Einheit -ne $null)
    #        {
                #Write-Host $Einheit.EinheitenNummer ' - ' $Einheit.FeuerwehrGruppe
    #        }
    #        else
    #        {
                ##Write-Host "Einheit "+$EinzelAlarmeinheit+" wurde nicht gefunden nächste Einheit wird ggfs. ausgelesen!"
                ##$EinheitenFehlerCounter = $EinheitenFehlerCounter + 1
    #        }
    #    }
    #Write-Host "AlarmStichwort: " $AlarmStichwortEingabe
    #Write-Host "AlarmText: "$AlarmTextDetailEingabe
    $AlarmBestaetigen ='n'
    $AlarmBestaetigen = Read-Host -Prompt "Bitte Alarm mit ja/Ja bestätigen! Andere Eingabe führen zum Abbruch und ins Hauptmenü zurück!"
    Write-Host ''
    if ($AlarmBestaetigen -eq 'ja' -or $AlarmBestaetigen -eq 'Ja')
    {
        #Write-Host 'Es erfolgt der Alarm!'
        write-AlarmLogRecord -Typ INFO '_______________________________________'
        write-AlarmLogRecord -Typ INFO '##### Manueller FEZ DIVERA Alarm #####'
        $Logtext = "Alarmstichwort: "+ $AlarmStichwortEingabe
        write-AlarmLogRecord -Typ INFO $Logtext
        $Logtext = "Alarmtext: " + $AlarmTextDetailEingabe
        write-AlarmLogRecord -Typ INFO $Logtext
        foreach($EinzelAlarmeinheit in $FEZAlarmEinheitenArr) 
        {
                $Einheit = $ConfigFileJSON.Einheiten.Where({$_.EinheitenNummer -eq $EinzelAlarmeinheit})
                If ($Einheit -ne $null)
                {
                    $AktuelleEinheitAlarmvorlageID = $Einheit.AlarmVorlagenID
                    $AktuelleEinheitGroupAlarmListCode = $Einheit.GroupAlarmListCode              
                    set-AlarmRueckfall $AlarmAusloesungScharf $AktuelleEinheitAlarmvorlageID $AktuelleEinheitGroupAlarmListCode $AlarmStichwortEingabe $AlarmTextDetailEingabe
                    $FEZAlarmLogString = "Einheiten Nummer: "+ $Einheit.EinheitenNummer + " - " + $Einheit.FeuerwehrGruppe +  " wurde alarmiert!"
                    Write-Host ''
                    write-AlarmLogRecord -Typ INFO $FEZAlarmLogString
                    Write-Host $FEZAlarmLogString
                }                
        }
        write-AlarmLogRecord -Typ INFO '##### ENDE Manueller FEZ DIVERA Alarm #####'
        write-AlarmLogRecord -Typ INFO '_______________________________________'
        Write-Host ''
        Write-Host 'Alarmierung abgeschlossen! Programm wird geschlossen'
        Write-Host ''
        Read-Host
        Exit
    }
    else
    {
        Write-Host 'Es erfolgt kein Alarm - Programm wieder im Hauptmenü!'
        Write-Host ''
        Read-Host
        FEZ-Menu
    }
}
###Alarm FEZ Menu Ende ######

#####################################Start##########################################################################
###Check Aufruf Parameter ###
if ($EinheitenIDs -ne '')
{
    FEZ-Menu $EinheitenIDs $AlarmStichwort $AlarmTextDetail
}
else
{
    FEZ-Menu
}


#####################################Ende##########################################################################

#Debugging




