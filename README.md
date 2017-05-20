flowd
=====

Direct copy of the flowd repo on google code:  https://code.google.com/p/flowd/

------
Import of netflow records from binary
flowd log files into a SQL database.

INSTALLATION
------------

1. Configure flowd in typical manner.

2. Create a MySQL database, create a traffic table with the following syntax:
```
CREATE TABLE IF NOT EXISTS `traffic` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `tag` int(10) unsigned NOT NULL,
  `received` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `agent_addr` varchar(64) NOT NULL,
  `src_addr` varchar(64) NOT NULL,
  `dst_addr` varchar(64) NOT NULL,
  `src_port` int(10) unsigned NOT NULL,
  `dst_port` int(10) unsigned NOT NULL,
  `octets` bigint(20) unsigned NOT NULL,
  `packets` bigint(20) unsigned NOT NULL,
  `protocol` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `received` (`received`),
  KEY `group by` (`src_addr`,`dst_addr`),
  KEY `group` (`received`,`src_addr`,`dst_addr`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;
```
3. Install the flowd_mysql_rotate.pl script.

4. Adjust options in the script to define MySQL host/database/user/table

USAGE
------

Call the script regularly to import the flowd records and rotate the record file to avoid slowly
filling up the disk.

For example, the following crontab entry.
15 * * * *      /opt/flowd/flowd_mysql_rotate.pl /var/log/flowd
