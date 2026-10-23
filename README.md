# *Art i Mar Cambrils*

- **Nombre del proyecto:**  Despliegue Seguro de E-commerce con Contenedores y Redes Segmentadas *Art i Mar Cambrils*
- **Integrantes:** Eduardo Zavarce Forsythe
- **Temática:** Despliegue de comercio electrónico local de artesanía marinera, decoración y cerámica con WordPress y MySQL sobre una arquitectura de red segmentada.

---
## MF0488 — Servidor, Monitorización e Infraestructura Docker

<details>
<summary>Detalles MF0488 </summary>

### 1. Guía de Instalación y Despliegue

#### Prerequisitos: 
- Servidor Ubuntu 22.04.5 LTS.

Para replicar y desplegar la infraestructura sobre un servidor base con Ubuntu 22.04.5 LTS, ejecute los siguientes pasos secuenciales desde la raíz del repositorio:

1. **Ejecutar los scripts de preparación del entorno e instalación:**
    ```bash
    ./scripts/00-initial-setup/00-create-folders.sh
    ./scripts/00-initial-setup/01-install-docker.sh
    ./scripts/00-initial-setup/02-install-dependencies.sh
    ```

2. **Configurar las variables de entorno:**
    
    Genere su archivo de configuración .env utilizando como base la plantilla proporcionada (template.env):

    ```bash
    cp template.env .env
    ```
    (Modifique los parámetros y credenciales dentro de .env según sea necesario para su entorno).

3. **Desplegar los contenedores:**

    Inicie la orquestación de servicios en segundo plano mediante Docker Compose:

    ```bash
    docker compose up -d
    ```

4. **Configuracion de monitorización:**

    ```bash
    ./scripts/01-suricata/00-install.sh
    ./scripts/01-suricata/01-config.sh
    ```
---

### 2. Descripción breve del sistema
La infraestructura representa un servidor virtual corporativo expuesto a internet simulando el entorno de producción de una tienda artesanal local. El servicio presta una plataforma web de comercio electrónico accesible públicamente para clientes y administración. Gestiona información ficticia de catálogo de productos artesanales, altas de usuarios, pedidos y transacciones comerciales simuladas. La aplicación web (WordPress) funciona como interfaz de cara al cliente y pasarela de gestión del negocio, operando de forma aislada de los datos críticos para garantizar la resiliencia y la seguridad de la información.

---

### 3. Tecnologías y Componentes Previstos

| Componente                 | Tecnología                | Función                                                                                            |
| :------------------------- | :------------------------ | :------------------------------------------------------------------------------------------------- |
| **Sistema principal**      | Ubuntu 22.04.5 LTS | Sistema operativo base para la administración y alojamiento de la infraestructura.                 |
| **Acceso remoto**          | OpenSSH Server            | Administración segura y remota del servidor host mediante consola cifrada.                         |
| **Ejecución de servicios** | Docker & Docker Compose   | Orquestación y aislamiento de los servicios mediante contenedores.                                 |
| **Servicio principal (WEB-01)**     | WordPress                 | Aplicación web de comercio electrónico (tienda en línea de artesanía).                             |
| **Persistencia (DB-01)**           | MariaDB                   | Sistema de gestión de bases de datos relacionales para el almacenamiento de contenidos y usuarios. |
| **Monitorización / IDS**   | Suricata                  | Sistema de detección de intrusiones en red para la supervisión del tráfico y alerta temprana.      |

---

### 4. Arquitectura inicial

```mermaid
graph TD
    classDef clientStyle fill:#f9f,stroke:#333,stroke-width:2px,color:#000;
    classDef adminStyle fill:#ff9999,stroke:#333,stroke-width:2px,color:#000;
    classDef hostStyle fill:#bbf,stroke:#333,stroke-width:2px,color:#000;
    classDef dmzStyle fill:#ffcc99,stroke:#333,stroke-width:2px,color:#000;
    classDef privStyle fill:#bfffbf,stroke:#333,stroke-width:2px,color:#000;
    classDef serviceStyle fill:#fff,stroke:#333,stroke-width:2px,color:#000;

    CLIENTE(("CLIENTE INTERNET")):::clientStyle -->|Tráfico Web / HTTPS| WEB
    ADMIN(("ADMINISTRADORES")):::adminStyle -->|Acceso Remoto SSH| SSH

    subgraph HOST ["Ubuntu Server 22.04 (192.168.1.39)"]
        SSH["SSH Server (OpenSSH)"]:::hostStyle
        Suricata["Suricata IDS (enp1s0)"]:::hostStyle
        
        subgraph DOCKER ["Docker Engine Bridge"]
            subgraph DMZ ["Red DMZ (172.20.10.0/24)"]
                WEB["WEB-01 WordPress (172.20.10.2)"]:::serviceStyle
            end
            subgraph PRIV ["Red Privada (172.20.20.0/24)"]
                DB[("DB-01 MariaDB (172.20.20.2)")]:::serviceStyle
            end
        end
    end

    class DMZ dmzStyle;
    class PRIV privStyle;

    WEB -.->|Consulta / Datos| DB
```

### 5. Configuración de Red y Puertos

Para garantizar la seguridad y la segmentación del tráfico, los puertos se han configurado minimizando la exposición pública de los servicios internos:

| Servicio / Componente | Puerto Expuesto (Host/VM) | Puerto en Contenedor | ¿Expuesto al exterior? | Función |
| :--- | :--- | :--- | :--- | :--- |
| **OpenSSH Server** | `22` | `22` | **Sí** | Administración remota segura del servidor host. |
| **WordPress (Web)** | `80` (HTTP) / `443` (HTTPS) | `80` / `443` | **Sí** | Acceso público de los clientes al e-commerce (*DMZ*). |
| **MariaDB (Base de datos)** | Ninguno | `3306` | **No** | Uso interno exclusivo para la persistencia de datos (*Red Privada aislada*). |

[Screenshots comprobación de configuraciones](docs/mf0488/validations/fase2/evidencias.md)

### 6. Mapa de Evidencias 

| Acción / Evento | Activo / Origen | Ubicación del Registro (Ruta / Servicio) | Datos Clave a Identificar |
| :--- | :--- | :--- | :--- |
| **Login SSH (Correcto / Incorrecto)** | Linux (Host) | `/var/log/auth.log` (o `journalctl -u ssh`) | Fecha/hora, IP de origen, Usuario, Resultado (Accepted / Failed). |
| **Petición HTTP (Correcta / Errónea)** | Web (`WEB-01`) / WordPress | Logs del contenedor Docker (`shop-wordpress`) | IP de origen, Hora, Método HTTP, URL, Código de Estado (200, 404...). |
| **Actividad de Contenedores** | Docker Engine | `/var/lib/docker/containers/` o `docker logs` | Timestamp, ID del contenedor, Mensajes de error o arranque. |

#### Evidencias:
[Screenshots de los logs](docs/mf0488/validations/fase3/evidencias.md)


---

### 7. Monitorización / IDS 

#### Suricata:

Elegido el IDS suricata para monitorear y generar alertas de actividad en la subred.

Agregada una regla para alertar peticiones de ICMP (ping).

[Configuración y pruebas](docs/mf0488/validations/fase4/evidencias.md)

---

### 8. Pruebas realizadas al entorno


| Acción | Fuente Principal de Registro | Detectada / Registrada | Información Obtenida (Detalles Clave) |
| --- | --- | --- | --- |
| **SSH correcto** | `/var/log/auth.log` | **Sí** | Fecha/hora, IP de origen, usuario autenticado, método de acceso (Accepted publickey/password). |
| **SSH incorrecto** | `/var/log/auth.log` | **Sí** | Fecha/hora, IP de origen, usuario intentado, fallo de autenticación (Failed password). |
| **Web válida** | Logs de contenedores Docker / WordPress | **Sí** | IP de origen, timestamp, método HTTP (`GET`), recurso solicitado (`/`), código de estado `200 OK`. |
| **Web 404** | Logs de contenedores Docker / WordPress | **Sí** | IP de origen, timestamp, recurso no existente solicitado, código de estado `404 Not Found`. |
| **Docker** | `docker logs` / Motor Docker | **Sí** | Timestamps de arranque, estado de los contenedores (`shop-wordpress`, `shop-mariadb`), mensajes de conectividad interna. |
| **Ping** | Suricata (`/var/log/suricata/fast.log`) | **Sí** | Alerta generada por regla propia (`sid:1000001`), IP origen del escaneo/ping, IP destino (`192.168.1.39`), protocolo ICMP. |
| **Nmap** | Suricata / Logs del sistema / Web logs | **Sí** | Identificación de barrido de puertos, peticiones múltiples concurrentes, registro de conexiones entrantes a servicios expuestos. |

[Screenshot de resultados](docs/mf0488/validations/fase5/evidencias.md)


---

</details>

## MF0489 — Fase 2: Autoridad Certificadora (CA) y Certificados TLS
<details>
<summary>Detalles MF0489</summary>

## 1. Arquitectura actualizada

```mermaid
graph TD
    classDef clientStyle fill:#f9f,stroke:#333,stroke-width:2px,color:#000;
    classDef adminStyle fill:#ff9999,stroke:#333,stroke-width:2px,color:#000;
    classDef hostStyle fill:#bbf,stroke:#333,stroke-width:2px,color:#000;
    classDef dmzStyle fill:#ffcc99,stroke:#333,stroke-width:2px,color:#000;
    classDef privStyle fill:#bfffbf,stroke:#333,stroke-width:2px,color:#000;
    classDef serviceStyle fill:#fff,stroke:#333,stroke-width:2px,color:#000;
    classDef caStyle fill:#e6ccff,stroke:#333,stroke-width:2px,color:#000;

    CLIENTE(("CLIENTE INTERNET")):::clientStyle -->|Tráfico HTTPS / Puerto 443| NGINX
    ADMIN(("ADMINISTRADORES")):::adminStyle -->|Acceso Remoto SSH / Puerto 22| SSH

    subgraph EXTERNAL ["Entorno Externo / Laboratorio"]
        CA["Autoridad Certificadora (CA Lab)<br/>(Fuera de la VM CTF)"]:::caStyle
    end

    subgraph HOST ["Ubuntu Server 22.04 (192.168.1.39)"]
        SSH["SSH Server (OpenSSH)"]:::hostStyle
        Suricata["Suricata IDS (enp2s0)"]:::hostStyle
        
        subgraph DOCKER ["Docker Engine Bridge"]
            subgraph DMZ ["Red DMZ (172.20.10.0/24)"]
                NGINX["Nginx Reverse Proxy<br/>(Terminación TLS - Port 443)"]:::serviceStyle
                WEB["WEB-01 WordPress (172.20.10.2)<br/>(Tráfico HTTP interno)"]:::serviceStyle
            end
            subgraph PRIV ["Red Privada (172.20.20.0/24)"]
                DB[("DB-01 MariaDB (172.20.20.2)")]:::serviceStyle
            end
        end
    end

    CA -.->|"Emisión de Certificado (SCP Automatizado)"| NGINX
    NGINX -.->|"Proxy Pass (HTTP)"| WEB
    WEB -.->|"Consulta / Datos"| DB

    class DMZ dmzStyle;
    class PRIV privStyle;
```
### 2. Configuración de Dominio y DNS del Proyecto

* **Nombre FQDN Seleccionado:** `portal.artimar.thm`
* **Justificación del TLD (`.thm`):**
  Aunque el estándar de la IETF (RFC 2606) reserva el sufijo `.test` para entornos de pruebas locales, se ha adoptado deliberadamente el TLD no estándar **`.thm`**. Esta decisión responde a que la arquitectura de este proyecto y la máquina virtual resultante han sido diseñadas para ser exportadas y desplegadas como un escenario de laboratorio CTF en la plataforma **TryHackMe**, la cual utiliza por convención este dominio de nivel superior en sus entornos de simulación.
* **Consistencia de Identidad:** El FQDN `portal.artimar.thm` se utiliza de forma estricta y uniforme en:
   - El *Common Name* (CN) y la extensión *Subject Alternative Name* (SAN) de la CSR del servidor.
   - El archivo de extensiones `servidor.ext` utilizado durante la firma por la CA.
   - El certificado X.509 final emitido (`servidor.crt`).
   - Las validaciones criptográficas de hostname mediante OpenSSL (`-verify_hostname portal.artimar.thm`).
  
### 3. Guía de Automatización y Despliegue PKI (Fase 2)

El despliegue y ciclo de vida de la infraestructura de clave pública (PKI) se gestiona de forma modular a través de scripts dedicados ubicados en `scripts/02-pki/`, apoyados por un sistema centralizado de carga de variables de entorno (`load-env-variables.sh`).

#### Requisito previo: Configuración de Entorno
Asegúrese de configurar sus parámetros de red y dominio en el archivo de entorno antes de ejecutar los scripts:
```bash
cp template.env .env
```
*(Edite `.env` para ajustar `DOMAIN_NAME`, `CA_MACHINE_ADDRESS`, `CA_MACHINE_USER`, `SERVER_ADDRESS` y `SERVER_USER`).*

#### Secuencia de Ejecución del Workflow PKI:

1. **Inicialización de la Autoridad Certificadora (Entorno CA):**
   Crea la estructura de directorios con máscara segura (`umask 077`), genera la clave privada de la CA cifrada con AES-256 y emite el certificado raíz autofirmado (`ca.crt`):
   ```bash
   ./scripts/02-pki/00-ca-setup.sh
   ```

2. **Generación y Envío Automático de la CSR (Entorno Servidor):**
   Genera la clave privada del servidor (RSA 3072) y la Solicitud de Firma de Certificado (CSR) incorporando el *Subject Alternative Name* (SAN) obligatorio para el dominio, enviándola automáticamente por `scp` a la máquina CA:
   ```bash
   ./scripts/02-pki/01-server-cert.sh
   ```

3. **Firma y Retorno Automático de Certificados (Entorno CA):**
   Procesar la CSR recibida en la CA, valida las restricciones de extensión para servidores web (`serverAuth` y SAN) y devuelve automáticamente de vuelta mediante `scp` el certificado firmado (`servidor.crt`) y el certificado raíz (`ca.crt`) al servidor:
   ```bash
   ./scripts/02-pki/02-sign-cert.sh
   ```

4. **Instalación y Validación Criptográfica Definitiva (Entorno Servidor):**
   Instala los certificados en las rutas protegidas del sistema operativo (`/etc/ssl/certs/`, `/etc/ssl/private/`), establece los permisos estrictos (`600`/`644`), verifica la cadena de confianza con OpenSSL (comprobando éxito y fallos por *hostname mismatch*) y valida las correspondencias de hash de las claves públicas antes de limpiar los temporales:
   ```bash
   ./scripts/02-pki/03-server-install.sh
   ```

---

### 4. Especificaciones Técnicas y de Seguridad

* **Terminación TLS:** Realizada en el borde perimetral (Nginx Reverse Proxy) para el puerto `443` (HTTPS).
* **Aislamiento de la CA:** La clave privada de la Autoridad Certificadora (`ca.key`) permanece aislada en el Entorno CA y nunca es expuesta en la red pública.
* **Permisos y Umask:** Todos los scripts aplican restricciones estrictas de privilegios (`umask 077`) para garantizar que las claves privadas de servidor y CA sean inaccesibles para usuarios no autorizados.

### 5. Evidencias y capturas de pantalla

- [Evidencias de la Autoridad Certificadora (CA)](docs/mf0489/validations/fase2/ca/evidencias.md)
- [Evidencias del Servidor](docs/mf0489/validations/fase2/server/evidencias.md)

</details>