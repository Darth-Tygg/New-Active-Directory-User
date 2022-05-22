<#
##################################################################

  Test Script to add users to Active Directory via PowerShell
  Project: For UAT Provisioning System (Network Email AD Tab)

  Comments and Logon Script info by: Jake Smith (6/30/16)
  Original Code: Ryan Adams (6/7/16)
  
  Last Updated: 3:00PM 7/12/2016 - Ryan Adams and Jake Smith

  ToDo: Add Exchange Email Set Up
  
  Testing Note: Jake has set up a test machine that mirrors
     PROD. This is a safe place to test adding users to 
     Active Directory to make sure things work correctly.
  
  DO NOT TEST IN PROD

##################################################################
#>

Import-Module ActiveDirectory
Set-Location AD:

#DC Account to allow new user to be added
$username = "Administrator"
$password = "PASSWORD"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr


#Path set up to configure the user's OUs; Should look similar to: OU=Information Technology,OU=Users,OU=local_level,OU=Company,DC=top_level_comp,DC=com
#Format (biggest to smallest): com, companyName, location, Users, department, specialCategories within department
#Note: Some departments like Claims and Underwriting will have the special categories
#Note 2: The path referenced above is located directly near the end of the New-ADUser command and is based on what is described above
$mainDC = "company"  #Company Name; Ex: acme, stark, doofenshmertz


#Setting up new user properties, the comment is the AD attribute name
#read-host takes input

#UI Tab: General
$GN = read-host "Enter givenName:"                   #givenName           Ex: John
$Surname = read-host "Enter sn:"                     #sn                  Ex: Doe
$Des = read-host "Enter description:"                #description         Ex: Full Time Employee / Contractor / System Account / Auditor / Intern / Test / Template
$Phone = read-host "Enter telephoneNumber:"          #telephoneNumber     Ex: 555.007.1234
$City = read-host "Enter Office:"                    #city, state

#UI Tab: Address
$streetAddress = read-host "Enter streetAddress:"    #streetAddress       Ex: 1234 Big Street Suite 007  Note: Determined the address based on the users location
$poBox = read-host "Enter postOfficeBox:"            #postOfficeBox       Ex: 1234, Somewhere, VA 12345-1234
$st = read-host "Enter state:"                       #st                  Ex: VA                                Note: State Depending on location
$postalCode = read-host "Enter postalCode:"          #postalCode          Ex" 12345                          
$country = read-host "Enter country:"                #c                   Ex: United States                     Note: Country

#UI Tab: Account
$SAN = read-host "Enter samAccountName:"             #samAccountName      Ex: jdoe                           Note: Will need a check availibility button to make sure it is unique
while( (Get-ADUser -Filter {sAMAccountName -eq $SAN}) -ne $Null) {
    $SAN = read-host "Username take. Enter new samAccountName:"
}


$ExpireDate = read-host "Enter accountExpires:"      #accountExpires      Ex: 10/31/2016                        Note: Obviously this will change

#UI Tab: Profile
$scriptName = read-host "Enter scriptName:"          #scriptPath          Ex: logon_script_IT.bat                     Note: Logon Script is based on the Position and Department. See below

#UI Tab: Telephones
$mobilephone = read-host "Enter Cell Phone:"         #mobile              Ex: 123.456.7890
$fax = read-host "Enter Fax number:"                 #fax   Ex: 123.456.7890
$floor = read-host "Enter floor:"
$workstation = read-host "Enter workstation:"
$info = @{'info'="$floor,$workstation"}              #info                Ex: 2,1021 

#UI Tab: Organization
$Title = read-host "Enter title:"                    #title               Ex: IT Intern
$Dep = read-host "Enter department:"                 #department          Ex: Information Technology
$COMP = read-host "Enter company:"                   #company             Ex: Company
$Manager = read-host "Enter manager:"                #manager             Ex: jdoe

$PW = read-host "Enter New_User_Password:" -AsSecureString #Format: FILastName#Year       Ex: jsmith#2016


#This is an array of groups the new user should be added to.
#The complete mapping of user groups is at: 
#\\FileServ\IT\Active Directory Mappings and Scripts\User_Groups_Mapping.xlsx
$userGroups = @("users","test")


#Creates user from above fields
New-ADUser -Name "$Surname, $GN" -SamAccountName $SAN -UserPrincipalName $SAN@domain.com -GivenName $GN -Surname $Surname -Department $Dep -Description $Des -Displayname "$Surname, $GN" -Office $City -streetAddress $streetAddress -poBox $poBox -City $City -State $st -postalCode $postalCode -country $country -Title $Title -Company $COMP -OfficePhone $Phone -Manager $Manager -mobilephone $mobilephone -fax $fax -OtherAttributes $info -AccountPassword $PW -scriptPath "\\Domain.com\NETLOGON\$scriptName" -HomeDirectory "\\FileServ\homedrive$\$SAN" -HomeDrive H -AccountExpirationDate $ExpireDate -Path "OU="$Dep,"OU=Users,OU=Local_Domain,OU=Company_Domain,DC=Top_Domain,DC=com" -Enabled 1 -Credential $cred                 


#Adds specified groups to the newly created user
Foreach($group in $userGroups) { Add-ADGroupMember $group $SAN }

<#
############################################################
Logon Script info:
 Accounting	                    logon_script_AC.bat
 HR                             logon_script_HR.bat
 IT                             logon_script_IT.bat
 Management                     logon_script_MG.bat
############################################################
#>



<#
############################################################

  Exchange code:

  if(!(Get-PSSnapin | 
   Where-Object {$_.name -eq "Microsoft.Exchange.Management.PowerShell.E2010"})) {
     ADD-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
   }

  $Database = read-host "Enter Email Database:"
  Enable-Mailbox -Identity $NAME -Alias $San -Database $Database

############################################################
#>