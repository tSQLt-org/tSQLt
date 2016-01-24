To get the new SigningKey accepted by the BuildAgent, follow these steps:


1) Run the failing build configuration and note the required key container
  a) run the configuration
  b) open the log and find the error:
    error MSB3325: Cannot import the following key file: SigningKey.pfx. The key file may be password protected. To correct this, try to import the certificate again or manually install the certificate to the Strong Name CSP with the following key container name: VS_KEY_FFAB74CD53FE74BA
  c) the key container name is at the end of the message
2) make sure the agent account is not in the "Deny log on locally" group policy
  a) Startmenu
  b) type gpedit.msc
  c) Computer Configuration/Windows Settings/Security Settings/Local Policies/User Rights Assignment
  d) check "Allow log on locally" and "Deny log on locally"
  (Adding an account to "Deny log on locally" prevents it from showing up on the winfows logo screen. Handy for service accounts.)
3) Run the Visual Studio Cmd Prompt from the service account
  a) https://msdn.microsoft.com/en-us/library/ms229859(v=vs.110).aspx
4) load the key with the sn tool
  a) CD to the path that contains the SigningKey.pfx  (tSQLt/tSQLtCLR/tSQLtCLR)
  b) run this: sn -i SigningKey.pfx VS_KEY_FFAB74CD53FE74BA
     (using the key container name from the error message above)
  c) provide the key password when prompted
5) Add the account back to the "Deny log on locally" group policy