Instructions to follow:-
--------------------------------


1) First run docker compose with below command:-
	
		docker compose up -d (-d will be used to run it in dettached mode)
		
2) Install Dependencies using below command (from docker webserver container bash):-

		bash /var/www/html/install.sh
		
3) To start a fpm after reboot or container restart use below commnand in webserver container 

		bash /var/www/html/startfpm.sh
		
		
		