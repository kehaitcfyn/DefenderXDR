# MalwareBazaar Database
MalwareBazaar Database er en gratis online trusselsdatabase som specialiserer sig i at indsamle og dele indikatorer for kompromittering (IoCs) relateret til malware og cybertrusler.
MalwareBazaar Database fokuserer på at give brugere adgang til IoCs såsom ondsindede hash-værdier, der er blevet associeret med skadelige aktiviteter såsom phishing, malware, og ransomware-kampagner.

https://bazaar.abuse.ch/browse/
# Løsningen
Min løsning går ud på at jagte filer og mails, hvor der forekommer en fil med en SHA256 værdi som ligger i MalwareBazaar  database.

PowerShell:
Henter seneste 250 IOC's fra MalwareBazaar 
Der generes en ny Json fil som Uploades til et Azure blobstorage som jeg derefter kan bruges i min KQL

KQL: 
Laver søgningen på DeviceFileEvents  samt EmailAttachmentInfo hvor SHA256 dukker op 


