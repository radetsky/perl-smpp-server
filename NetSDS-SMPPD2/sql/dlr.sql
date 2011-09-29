create table delivery_requests ( 
	message_id varchar(64) NOT NULL, 
	expire timestamp NOT NULL default now()
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

