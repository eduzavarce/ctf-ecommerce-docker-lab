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

    CA -.->|"Emisión de Certificado (Fuera de línea)"| NGINX
    NGINX -.->|"Proxy Pass (HTTP)"| WEB
    WEB -.->|"Consulta / Datos"| DB

    class DMZ dmzStyle;
    class PRIV privStyle;
```

### Punto de terminación TLS
La terminación de las comunicaciones cifradas (TLS) se implementa en el borde perimetral del servidor, concretamente en el **Nginx Reverse Proxy**. Toda conexión entrante realizada por los clientes a través de la red exterior mediante el puerto `443` (HTTPS) finaliza en este componente. Nginx se encarga de negociar los algoritmos de cifrado, presentar el certificado digital del servidor y descifrar la carga útil del tráfico web.

### Gestión de certificados y Autoridad Certificadora (CA)
* **Nginx Reverse Proxy:** Gestiona en tiempo de ejecución la presentación del certificado digital del servidor (`servidor.crt`) y su clave privada asociada (`servidor.key`), la cual permanecerá con permisos restringidos de lectura dentro del sistema host/contenedor.
  * **Autoridad Certificadora (CA de Laboratorio):** La CA se mantiene estrictamente en un entorno separado e independiente fuera de la máquina virtual/servidor CTF de producción. La clave privada de la CA (`ca.key`) nunca se transfiere a la infraestructura pública o expuesta. Únicamente se exportará el certificado público de la CA (`ca.crt`) hacia el servidor o los clientes para establecer la cadena de confianza.

### Comunicaciones internas y redes Docker
* **Red DMZ (`172.20.10.0/24`):** Alberga al proxy inverso Nginx y al servidor de aplicaciones web (`WEB-01` WordPress). La comunicación posterior al Nginx hacia WordPress se realiza mediante tráficos en texto plano (HTTP) dentro de la red interna de Docker. Esto evita sobrecargas innecesarias de re-cifrado interno mientras la aplicación se mantiene aislada del exterior.
  * **Red Privada (`172.20.20.0/24`):** Aloja la base de datos MariaDB (`DB-01`). WordPress se comunica directamente con la base de datos a través de esta red dedicada, estando la base de datos completamente incomunicada respecto al exterior y a la red DMZ no autorizada.

### Visibilidad del Sistema de Detección de Intrusiones (Suricata)
**Suricata** permanece configurado en la interfaz de red física exterior del sistema host (`enp2s0`).
* **Tráfico observable:** Suricata inspecciona las tramas de red a nivel perimetral, detectando los handshakes TLS, las IPs de origen/destino, puertos de conexión (443/22) e intentos de escaneo de puertos.
  * **Limitación de inspección profunda:** Dado que la conexión se encuentra cifrada entre el cliente y Nginx, Suricata no podrá realizar inspección profunda de paquetes (DPI) sobre las URIs o contenido HTTP enviado dentro del túnel HTTPS, permitiendo posteriormente comparar y correlacionar lo observado por el IDS frente a los registros de acceso descifrados de Nginx.

</details>
