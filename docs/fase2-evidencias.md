# Evidencias y Verificación — Fase 2: Servidor e Infraestructura Docker

## 1. Ubuntu Operativo

![os version](media/os_version.png)

## 2. SSH Operativo
![ssh status](media/ssh_status.png)

## 3. Docker Instalado

![docker status](media/docker_status.png)

## 4. Docker Compose Instalado
![docker compose](media/docker_compose_version.png)

## 5. Web Funcionando (WEB-01 / WordPress)

![wordpress_container](media/wordpress-docker-container.png)

![wordpress web screenshot](media/wordpress-browser.png)

## 6. Base de Datos Funcionando (DB-01 / MariaDB)

![mariadb container](media/mariadb-container.png)

![mariadb logs](media/mariadb-logs.png)

## 7. Comunicación Web ↔ DB
![web-service networks](media/wordperss-container-networks.png)

![private network containers](media/private-network-containers.png)

## 8. Persistencia (Bind Mounts y Volúmenes)

* **Método de comprobación:** Comprobación de que los archivos de WordPress residen en el directorio del host `/srv/wordpress` y los datos de MariaDB en el volumen Docker.
* **Comando ejecutado:**
```bash
ls -la /srv/wordpress
docker volume ls

```
- Wordpress bound directory: 

	![wordpress directory](media/wordpress-directory-list.png)
- MariaDB volume: 

	![mariadb volume](media/mariadb-volume.png)

## 9. Puertos Documentados

![ss ports](media/ss-ports.png)
![nmap](media/nmap.png)


## 10. GitHub Actualizado

![git fase 2](media/git-fase2.png)

