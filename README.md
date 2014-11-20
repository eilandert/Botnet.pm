This is a SpamAssassin module. Comitted to github for archieving purposes.

This is Botnet 0.9b.

Changelog from 0.8 to 0.9beta
- IPv6 Support
- Dns timeouts implemented
- Beter handling of timeouts/nonexisting dns

Altough it doesn't use the latest SA functions, it works on SpamAssassin 3.4.0.
I might pick this one up one day, since the original author seems to have abandonded it.


Botnet looks for possible botnet sources of email by checking
various DNS values that indicate things such as other ISP's clients or
workstations, or misconfigured DNS settings that are more likely to happen
with client or workstation addresses than servers.

Installing:
   Copy Botnet.pm and Botnet.cf into /etc/spamassassin (or whatever
   directory you use for your plugins).  If you use something like
   spamc/spamd, mailscanner, or a milter, you probably need to restart
   that.  From there, it should "just work".


