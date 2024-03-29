# Script SAVE BDD SQL SERVER
# Igor LEFORT 
# v1.1
#Ne sauvegarde plus les bases systémes (master, tempdb, model, msdb
# 2013/02/12

#Chargement des librairies SQL
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo')            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc')            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
#Spécifique à SQL 2008                 
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended')    

#Variable
$code_erreur_sortie = 0 #Code par défaut à 0
$Instance = "S17-BD01-PR\S17SICCPARIS" #de tyype [Serveur]\[Instance]. Mettre à jour le fichier hosts du serveur
$Destination = "E:\BACKUP\"    #Dossier de sauvegarde. Il faut qu'il existe
$log = $destination+"logs\saves_"+$Instance.Replace('\', '_')+"_"+(Get-Date -format yyyy-MM-dd)+".log" #fichier log
$user_admin = "sa";
$user_password = "S17SICCPARIS";

Start-Transcript -path $log #démarrage des logs

$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Instance

#On passe en connexion sa. Rempalcer l
$srv.ConnectionContext.LoginSecure=$false 
$srv.ConnectionContext.set_Login($user_admin) 
$srv.ConnectionContext.set_Password($user_password)
           
Write-Output ("Sauvegarde des bases de l'instance " + $Instance + " commencé à: " + (Get-Date -format yyyy-MM-dd-HH:mm:ss))


Try {

    foreach ($db in $srv.Databases)            
    {            
        If (($db.Name -ne "master") -and ($db.Name -ne "tempdb") -and ($db.Name -ne "model") -and ($db.Name -ne "msdb"))
        {   
                 
            $timestamp = Get-Date -format yyyy_MM_dd_HH_mm
            $fichier_destination = $Destination + $db.Name + "_full_" + $timestamp + ".bak"
            $description =  "Sauvegarde complete de " + $db.Name + " " + $timestamp          
             
            $sauvegarde = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")            
            $sauvegarde.Action = "Database"            
            $sauvegarde.Database = $db.Name
            $sauvegarde.Devices.AddDevice($fichier_destination, "File")         
            $sauvegarde.BackupSetDescription = $description       
            $sauvegarde.Incremental = 0            
               
            Write-Output ("Base: "+ $db.Name)
            Write-Output ("Nom Fichier: "+ $fichier_destination) 
            
           Try
            {   
            $sauvegarde.SqlBackup($srv)  
           }
            
           Catch 
           {
           Write-Output("Erreur sur la sauvegarde, vérifier les paramétres") 
            $code_erreur_sortie = 10
           }  
          
          
          
            #If ($db.RecoveryModel -ne 3)            
            #{            
            #    $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss            
            #    $sauvegarde = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")            
            #    $sauvegarde.Action = "Log"            
            #    $sauvegarde.Database = $db.Name            
            #    $sauvegarde.Devices.AddDevice($Destination + $db.Name + "_log_" + $timestamp + ".trn", "File")            
            #    $sauvegarde.BackupSetDescription = "Log backup of " + $db.Name + " " + $timestamp            
            # 
            #    $sauvegarde.LogTruncation = "Truncate"
            #
            #    $sauvegarde.SqlBackup($srv)            
            #}            
        }            
    } 
}

Catch {
    Write-Output("Erreur sur la base de donnée, vérifier les paramétres") 
   $code_erreur_sortie = 10
}

           
Write-Output ("Termine a: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss))

#Purge des anciennes sauvegardes / logs
# Pour désactiver la purge, mettre la variable $activer_purge à 0;

$activer_purge = 1;

If ($activer_purge -eq 1)
{
$datejour=get-date -uformat "%Y-%m-%d"
$jour_a_supprimer = 4

$jour = Get-Date

$dernier_modification = $jour.AddDays(-$jour_a_supprimer)


$Files = get-childitem $destination -include *.* -recurse | Where {$_.LastWriteTime -le $dernier_modification} 
 try 
 {
     foreach ($File in $Files) 
     { 
     	Write-Output ("Suppression de "+$File)
        Remove-Item $File
     } 
 }
 Catch 
 {
    Write-Output ("Erreur sur la suppression des fichiers de plus de "+$jour_a_supprimer+" jour(s)")
 }
 
 }

exit $code_erreur_sortie
