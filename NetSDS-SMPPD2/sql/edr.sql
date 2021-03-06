create table smppd_events ( 
	event_id int(11) not null auto_increment, 
	moment timestamp NOT NULL default CURRENT_TIMESTAMP,
	event_name varchar(32) default null, 
	src_addr_port varchar(32) default null,  
	system_id varchar(32) default null,  
	cmd_id smallint default null,
	cmd_status smallint default null, 
	src varchar (32) default null, 
	dst varchar (32) default null,
	userfield varchar(512) default null, 
	text varchar (256) default null,
	primary key (event_id) 
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Table for Event Logger';
