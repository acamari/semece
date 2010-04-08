all:
	sh ./tool/gen_startup_pl > startup.pl
	sh ./tool/gen_httpd_conf > httpd.conf
