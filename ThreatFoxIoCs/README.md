# ThreatFox
ThreatFox er en gratis online trusselsdatabase drevet af Abuse.ch, som specialiserer sig i at indsamle og dele indikatorer for kompromittering (IoCs) relateret til malware og cybertrusler. ThreatFox fokuserer på at give brugere adgang til IoCs såsom ondsindede domæner, IP-adresser, URL'er, og fil-hash-værdier, der er blevet associeret med skadelige aktiviteter såsom phishing, malware, og ransomware-kampagner.

https://threatfox.abuse.ch/api/

# Løsningen
Min løsning går ud på at jagte filer og mails, hvor der forekommer en fil med en SHA256 værdi som ligger i ThreatFox database.

PowerShell:
Henter IOC's for de seneste 7 dage fra ThreatFox API.
Trækker de data ud som jeg ønsker. Der generes en ny Json fil som Uploades til et Azure blobstorage som jeg derefter kan bruges i min KQL

KQL: 
Laver søgningen på DeviceFileEvents  samt EmailAttachmentInfo hvor SHA256 dukker op 

nyfull_sha256.json:
Eks. på en Json fil


# Har designet en bedre løsning som er baseret på https://bazaar.abuse.ch/  databasen
https://github.com/kehaitcfyn/DefenderXDR/tree/main/bazaar.abuse.ch
