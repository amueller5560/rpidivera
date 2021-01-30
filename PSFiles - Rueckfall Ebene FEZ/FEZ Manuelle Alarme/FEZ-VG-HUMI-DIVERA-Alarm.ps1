<#
.SYNOPSIS
    ####### Manueller DIVERA FEZ Alarm #######
    ####### Hilfe & Anleitung #######
    Das manueller Alarm Skript kann gezielt Gruppen/Untereinheiten in DIVERA24/7 ansprechen.
	Anwendungsfall ist hier nur der manuelle Aufruf via FEZ Personal
    
.DESCRIPTION
    Die gew�nschten FWs oder Gruppen werden via Nummerierung aufgerufen. Im Hintergrund sind die ben�tigten RICs im Config File hinterlegt.
    Optional sind die Parameter f�r Alarm Stichwort und Alarm Text.
    Sind diese Parameter nicht belegt wird als Stichwort beispielhaft:
    FW Ort - Alarm �ber FEZ
    Wehrf�hrer FW Ort - Alarm �ber FEZ
    ausgegeben.
.PARAMETER EinheitenIDs
    Die Einheiten k�nnen gezielt beim Aufruf mit �bernommen werden.
    Die Eingabe erfolgt Komma getrennt.
    '21,22,23'
    Siehe angef�gte Beispiele
.PARAMETER AlarmStichwort
    Dieser Parameter kann optional als Alarmstichwort mitgeben werden.
    Ist dieser Parameter nicht belegt wird als Stichwort beispielhaft:
    FW Ort - R�ckfallebene
    Wehrf�hrer FW Ort - R�ckfallebene
    ausgegeben.
.PARAMETER AlarmTextDetail
    Dieser Parameter kann optional als Alarm Text mitgeben werden.
    Bei Nichtbef�llung steht sonst im Alarmtext immer:
    Automatischer Alarm �ber R�ckfallebene - keine Details vorhanden    

.NOTES
    Author: Andreas M�ller - amueller@feuerwehr-biebernheim.de
    Last Edit: 2021-01-30
    *   Version 1.0.0 - 01.02.2021 - initiale Version 

.EXAMPLE
        Aufruf ohne Parameter
        ./FEZ-VG-HUMI-DIVERA-Alarm.ps1
        Alarmauswahl erfolgt �ber das Men�
.EXAMPLE
        Aufruf mit �bergabe von Einheiten 
        ./FEZ-VG-HUMI-DIVERA-Alarm.ps1 '21,22,23'
        Das Men� wird nicht angezeigt und werden direkt die �bergebenen Einheiten in die Alarmierung �bernommen.
        Im Anschluss kann der Alarmtext (optional) eingegeben werden. Das Stichwort lautet immer: Einsatzalarm 

        Wichtig: Die Parameter m�ssen in einfache 'Hochkommas' gesetzt werden!!!
.EXAMPLE
        Aufruf mit �bergabe von Einheiten & Stichwort $ Alarmtext 
        ./FEZ-VG-HUMI-DIVERA-Alarm.ps1 '21,22,23' 'Alarmstichwort Beispiel' 'Alarmtext Beispiel Test 1234'

        Das Men� wird nicht angezeigt und werden direkt die �bergebenen Einheiten in die Alarmierung �bernommen.
        Weiterhin wird das Alarmstichwort und der Text direkt und angezeigt. Dies muss nur noch best�tigt werden. 

        Wichtig: Die Parameter m�ssen in einfache 'Hochkommas' gesetzt werden!!!

#>

param(
  [Parameter(Mandatory = $false,Position = 0,HelpMessage = "Aufrufparameter f�r FEZ Massenalarm - hier wird die IDs der Einheiten komma separiert mitgegeben!")]
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
$ConfigFilePath = $ConfigFilePath.Path + '\' + 'VG-HUMI-DIVERA-Einheiten-GruppenFEZ.txt'
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

  # Generieren des Zeitstempels f�r die einzelnen LogZeilen            
  $TimeStamp = Get-Date -Format "[dd.MM.yyyy HH:mm:ss]"

  # Inhalt entsprechend Formatieren und zusammensetzen            
  $LogInhalt = "{0,-25}{1,-12}{2}" -f $TimeStamp,$Typ,$Text

  # Hinzuf�gen zum LogFile            
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
      curl $AlarmAufrufUrl
      
      #write-AlarmLogRecord -Typ INFO 'Alarm ausgel�st mit Stichwort und Textdetail!'
      #write-AlarmLogRecord -Typ INFO 'Ende'
    }
    if ($AlarmStichwortBool -eq $true -and $AlarmTextDetailBool -eq $false)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmStichwort + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      curl $AlarmAufrufUrl
           
      #write-AlarmLogRecord -Typ INFO 'Alarm ausgel�st mit Stichwort!'
      #write-AlarmLogRecord -Typ INFO 'Ende'
    }
    if ($AlarmStichwortBool -eq $false -and $AlarmTextDetailBool -eq $true)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmTextDetail + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      curl $AlarmAufrufUrl
           
      #write-AlarmLogRecord -Typ INFO 'Alarm ausgel�st mit Textdetail!'
      #write-AlarmLogRecord -Typ INFO 'Ende'
    }
    if ($AlarmStichwortBool -eq $false -and $AlarmTextDetailBool -eq $false)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      curl $AlarmAufrufUrl
      
      #Windows XP Web Aufruf:
      #WinXP-WebRequest $AlarmAufrufUrl

      #write-AlarmLogRecord -Typ INFO 'Alarm ausgel�st ohne weitere Details!'
      #write-AlarmLogRecord -Typ INFO 'Ende'
    }
  }
  else
  {
    write-AlarmLogRecord -Typ INFO 'Alarm nur via Log Durchlauf ausgel�st da Debug an!'
    #write-AlarmLogRecord -Typ INFO 'Ende'
  }

}
##############################################Alarm Setter Funktion Ende############################################


###Check Aufruf Parameter Ende ###


###Check LogFileExists###
# LogFile Pr�fen und erstellen falls nicht vorhanden


$CompleteLogPath = $LogPfad + "\" + $LogDatum + "_FEZAlarmLogFile.txt"

if (!(Test-Path ($CompleteLogPath)))
{
  # Erstellen des LogFiles            
  $Logfile = (New-Item ($CompleteLogPath) -ItemType File -Force).FullName

  # �berschrift f�r das LogFile            
  Add-Content $Logfile ("Die Alarm LogDatei wurde erstellt am $(get-date -Format "dddd dd. MMMM yyyy HH:mm:ss") Uhr`n").ToUpper()

  # Leerzeilen einf�gen            
  Add-Content $Logfile "`n`n"

  # Spalten�berschrift generieren            
  $LogInhalt = "{0,-25}{1,-12}{2}" -f "Zeitstempel","Typ","Logtext"

  # �berschrift dem Logfile hinzuf�gen            
  Add-Content $Logfile $LogInhalt
}
else
{
  # Falls Logfile schon vorhanden, Datei in die Variabel $Logfile aufnehmen            
  $Logfile = (Get-Item ($CompleteLogPath)).FullName

}
$ConfigFilePath = Get-Location
$ConfigFilePath = $ConfigFilePath.Path + '\' + 'VG-HUMI-DIVERA-Einheiten-GruppenFEZ.txt'


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
        #Write-Host 'Es wurden Einheiten beim Aufruf mitgeben diese werden nun �bernommen!'
        $OutPutString ='Es wurden Einheiten beim Aufruf mitgeben diese werden nun �bernommen!'
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
    Write-Host '- - - - - - - - - - - - - - - - - - -'
    #$OutPutString += '- - - - - - - - - - - - - - - - - - -'
    foreach($Einzeleinheit in $FEZAlarmEinheitenArr) 
        {
            ##$u.surname
            $Einheit = $ConfigFileJSON.Einheiten.Where({$_.EinheitenNummer -eq $Einzeleinheit})
            If ($Einheit -ne $null)
            {
                $FEZAlarmEinheitenAlarmArr = $FEZAlarmEinheitenAlarmArr + $Einzeleinheit
                Write-Host $Einheit.EinheitenNummer ' - ' $Einheit.FeuerwehrGruppe
                #$OutPutString +=$Einheit.EinheitenNummer + ' - ' + $Einheit.FeuerwehrGruppe | Out-String
                #Write-Host ''
                $EinheitenCounter = $EinheitenCounter + 1
            }
            else
            {
                #Write-Host 'Einheit '$Einzeleinheit' nicht gefunden n�chste Einheit wird ggfs. ausgelesen!'
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
        Write-Host "Es wurden insgesamt "$EinheitenCounter" Einheit(en) gefunden - "$EinheitenFehlerCounter" Einheit(en) wurden nicht gefunden werden verworfen!"
        #$OutPutString += "Es wurden insgesamt "+$EinheitenCounter+" Einheit(en) gefunden - "+$EinheitenFehlerCounter+"Einheit(en) wurden nicht gefunden werden verworfen!"
        #Write-Host $OutPutString | Out-String
        #Write-Host ''

    }   
    #$AlarmStichwortEingabe = Read-Host -Prompt "Bitte geben Sie das gew�nschte Alarmstichwort ein!"
    if($AlarmStichwort -ne '')
    {
        #Write-Host 'Es wurde ein AlarmStichwort mitgeben. Dieses wird nun �bernommen'
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
        #Write-Host 'Es wurde ein Alarmtext mitgeben. Dieses wird nun �bernommen'
        Write-Host "AlarmText: " $AlarmTextDetail
        Write-Host ''
        $AlarmTextDetailEingabe = $AlarmTextDetail
    }
    else
    {
         $AlarmTextDetailEingabe =  Read-Host -Prompt "Bitte geben Sie den gew�nschte Alarmtext ein (optional)!"
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
                ##Write-Host "Einheit "+$EinzelAlarmeinheit+" wurde nicht gefunden n�chste Einheit wird ggfs. ausgelesen!"
                ##$EinheitenFehlerCounter = $EinheitenFehlerCounter + 1
    #        }
    #    }
    #Write-Host "AlarmStichwort: " $AlarmStichwortEingabe
    #Write-Host "AlarmText: "$AlarmTextDetailEingabe
    $AlarmBestaetigen ='n'
    $AlarmBestaetigen = Read-Host -Prompt "Bitte Alarm mit ja/Ja best�tigen! Andere Eingabe f�hren zum Abbruch und ins Hauptmen� zur�ck!"
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
                    set-AlarmRueckfall $AlarmAusloesungScharf $AktuelleEinheitAlarmvorlageID $AlarmStichwortEingabe $AlarmTextDetailEingabe
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
        Write-Host 'Es erfolgt kein Alarm - Programm wieder im Hauptmen�!'
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




