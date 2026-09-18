# Ejecución de Pruebas

- SSH correcto

	```bash
	sudo grep "Accepted" /var/log/auth.log
	```

	![ssh-success](media/ssh-success.png)

- SSH incorrecto
	```bash
		sudo grep "Failed" /var/log/auth.log
	```

	![ssh failed](media/ssh-failed.png)

- Web válida

	```bash
	docker logs shop-wordpress | grep "HTTP/1.1\" 200"
	```
	![web-ok](media/web-ok.png)

- Web 404

	```bash
	docker logs shop-wordpress | grep "HTTP/1.1\" 404"
	```

	![404](media/404.png)

- Docker

	```bash
	sudo journalctl -u docker --since "1 hour ago"
	```

	![docker](media/docker.png)

- Ping

	```bash
	sudo tail -n 20 /var/log/suricata/fast.log
	```
	![ping](media/ping-suricata-logs.png)




- Nmap

	```bash
	nmap -sV -p- 192.168.1.39

	```
	![nmap](media/nmap.png)


