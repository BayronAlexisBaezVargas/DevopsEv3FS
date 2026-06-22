# 🐾 Devows (DNF) - Plataforma de Rescate y Adopción de Mascotas

Devows es una plataforma basada en arquitectura de microservicios diseñada para ayudar a las comunidades a reportar, buscar y encontrar mascotas perdidas. Utiliza algoritmos de coincidencia y notificaciones en tiempo real para agilizar los reencuentros.

Este repositorio contiene el código fuente completo del Frontend, Backend, Manifiestos de Kubernetes y la Infraestructura como Código (Terraform) necesaria para desplegar el proyecto en **Amazon Elastic Kubernetes Service (EKS)**.

---

## 🏛️ Arquitectura del Sistema

El proyecto está diseñado bajo un enfoque nativo de la nube (Cloud-Native), dividiendo sus responsabilidades en los siguientes componentes:

*   **Frontend**: Aplicación Single Page Application (SPA) y Backend-for-Frontend (BFF) construida con React, Vite y Express.
*   **API Gateway & Service Discovery**: Enrutamiento centralizado usando Spring Cloud Gateway y descubrimiento de servicios con Eureka Server.
*   **Microservicios (Spring Boot)**:
    *   `Ms-usuario`: Gestión de usuarios, autenticación (JWT) y perfiles.
    *   `Ms-mascota`: Registro y reporte de mascotas perdidas/encontradas.
    *   `Ms-coincidencias`: Motor de emparejamiento entre reportes de pérdidas y hallazgos.
    *   `Ms-comunidad`: Gestión de historias de éxito y foros comunitarios.
    *   `Ms-notificaciones`: Sistema de alertas (RabbitMQ).
*   **Capa de Datos**: PostgreSQL (Persistencia relacional), Redis (Caché), RabbitMQ (Mensajería asíncrona). Todo aprovisionado en una instancia EC2 dedicada dentro de la misma VPC.
*   **Orquestación e Infraestructura**: Kubernetes (Amazon EKS) y Terraform.

---

## 🚀 Guía de Despliegue (AWS Academy)

Este proyecto está optimizado para funcionar dentro de las restricciones de **AWS Academy Learner Labs** (uso de `LabRole`, límites de zonas de disponibilidad, etc.).

### 1. Prerrequisitos
*   Tener configuradas tus credenciales de AWS CLI (`aws configure`).
*   Tener instalado Terraform y `kubectl`.

### 2. Levantar la Infraestructura (Terraform)
Ingresa a la carpeta `terraform` y despliega la infraestructura base (VPC, Base de datos, ECR y Clúster EKS):

```bash
cd terraform
terraform init
terraform apply -auto-approve
```
*(Este proceso tardará aproximadamente entre 10 a 15 minutos en crear el clúster de Kubernetes).*

### 3. Configurar GitHub Actions (Pipelines CI/CD)
En tu repositorio de GitHub, dirígete a **Settings > Secrets and variables > Actions** y agrega los siguientes "Repository secrets":

1.  `AWS_ACCESS_KEY_ID` (Cópialo de tu panel de AWS Academy)
2.  `AWS_SECRET_ACCESS_KEY` (Cópialo de tu panel de AWS Academy)
3.  `AWS_SESSION_TOKEN` (Cópialo de tu panel de AWS Academy)
4.  `CLUSTER_NAME`: **devows-project-eks-cluster** (Nombre estático del clúster EKS).

### 4. Ejecutar el Despliegue Automático
1.  Haz cualquier cambio en el repositorio y haz `push` a la rama `master`.
2.  Ve a la pestaña **Actions** en GitHub.
3.  El pipeline de **Backend** compilará las imágenes de Docker, inyectará la IP de la base de datos mágicamente en Kubernetes y desplegará los microservicios.
4.  Una vez termine el Backend, el pipeline del **Frontend** leerá el DNS del Load Balancer del API Gateway y se conectará automáticamente.

### 5. Acceder a la Aplicación
Conéctate a tu clúster desde la terminal:
```bash
aws eks update-kubeconfig --region us-east-1 --name devows-project-eks-cluster
```
Obtén la URL pública del Frontend:
```bash
kubectl get svc frontend
```
Copia el enlace que aparece debajo de `EXTERNAL-IP` y pégalo en tu navegador. *(Nota: AWS puede tardar hasta 3 minutos en propagar el DNS).*

---

## 💡 Notas Importantes sobre Costos (AWS Academy)

⚠️ **El clúster EKS consume saldo incluso si el laboratorio está apagado.** Si no vas a trabajar en el proyecto por varios días, se recomienda **destruir la infraestructura** para proteger tu presupuesto de los $100 dólares de AWS Academy:

```bash
cd terraform
terraform destroy -auto-approve
```

Cuando vuelvas a trabajar, simplemente ejecuta `terraform apply` y luego entra a GitHub Actions y presiona **"Re-run all jobs"** en tus pipelines para que todo vuelva a la vida de forma automática.

---
*Desarrollado para la Evaluación Parcial N°3 - Introducción a Herramientas Devops.*
