# `acme.sh` with Google Cloud SDK

For those who wish to use the [Google Cloud DNS API](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#49-use-google-cloud-dns-api-to-automatically-issue-cert) with [acme.sh](https://github.com/acmesh-official/acme.sh) running in a container environment, this is the container for you. This creates a Docker image with [Google Cloud SDK](https://cloud.google.com/sdk/) and [acme.sh](https://github.com/acmesh-official/acme.sh) installed and running on [Alpine Linux](https://hub.docker.com/_/alpine/). It is published for 32- and 64-bit `x86` and `ARM` architectures and, for those who use [Docker Swarm](https://docs.docker.com/engine/swarm/), it supports [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)

[![Docker Pulls](https://img.shields.io/docker/pulls/jmcombs/acme.sh-gcloud)](https://hub.docker.com/r/jmcombs/acme.sh-gcloud "Click to view the image on Docker Hub")
[![Docker Stars](https://img.shields.io/docker/stars/jmcombs/acme.sh-gcloud)](https://hub.docker.com/r/jmcombs/acme.sh-gcloud "Click to view the image on Docker Hub")

## How to Use

This container supports both: [Authorize with a service account](https://cloud.google.com/sdk/docs/authorizing#authorize_with_a_service_account) and [Authorize with a user account](https://cloud.google.com/sdk/docs/authorizing#run_gcloud_init).

**Requirements:**

- In order for **`gcloud`** authorization to remain persistent across container reboots, upgrades, etc., a persistant Docker Volme will need to be mapped to **`/root/.config/gcloud`**. Instructions below reference said persistant Docker Volume as **`gclouddata`**

**Assumptions:**

- For Docker Swarm:
  - In the instructions below, the Volume containing configuration data related to `acme.sh` is referenced as: **`acmedata`**
  - If leveraging Docker Secrets, in the instructions below the Docker Secret is referenced as: **`my_secret`**
  - If mapping Service Account via File to Docker Container, in the instructions below the Volume continaing the Service Account File is referenced as: **`gcloudsvcaccount`**
  - In the instructions below, the Docker Network is referenced as: **`my_network`**
- For Docker Desktop:
  - Instructions below will name and reference the Container as **`acmesh-gcloud`**
- For both Docker Desktop and Docker Swarm:
  - The below instructions reference Environment Variable: **`GCP_SERVICE_ACCOUNT_FILE`** which is used for Service Account authorizations
  - All examples below assume `acme.sh` will be ran as a Docker Daemon

**NOTE:** These instructions supersede [49. Use Google Cloud DNS API to automatically issue cert](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#49-use-google-cloud-dns-api-to-automatically-issue-cert)

#### **Authorize with a Service Account**

1. Follow Steps 1 through 4 on [Authorize with a service account](https://cloud.google.com/sdk/docs/authorizing#authorize_with_a_service_account) to create the Service Account and download the Key File.

   **NOTE** Take note of the email address assigned to the Service Account, you will need this later.

2. Map Service Account to Container with Docker Secrets: (Skip to Step 3 if not leveraging Docker Secrets)

   1. Create Docker Secret:
      ```sh
      docker secret create my_secret ./google_service_account_file.json
      ```
   2. Map Docker Secret to **`GCP_SERVICE_ACCOUNT_FILE`** environment variable

      Example `docker-compose.yaml` for Docker Swarm:

      ```yaml
      version: "3.8"

      services:
        acmesh:
          image: jmcombs/acme.sh-gcloud
          volumes:
            - acmedata:/acme.sh
            - gclouddata:/root/.config/gcloud
          secrets:
            - my_secret
          networks:
            - my_network
          environment:
            GCP_SERVICE_ACCOUNT_FILE: /run/secrets/my_secret
          command: daemon
          deploy:
            mode: replicated
            replicas: 1

      secrets:
        my_secret:
          external: true

      networks:
        my_network:
          external: true

      volumes:
        acmedata: ...
        gclouddata: ...
      ```

3. Map Service Account (Key) File to Container:

   1. Map Service Account (Key) File to Container and **`GCP_SERVICE_ACCOUNT_FILE`** environment variable

      Example `docker-compose.yaml` for Docker Desktop:

      ```yaml
      version: "3.8"

      services:
        acmesh:
          container_name: acmesh-gcloud
          image: jmcombs/acme.sh-gcloud
          volumes:
            - /your/local/filesystem/acmedata:/acme.sh
            - /your/local/filesystem/gclouddata:/root/.config/gcloud
            - /your/local/filesystem/gcloudsvcaccount:/tmp
          environment:
            GCP_SERVICE_ACCOUNT_FILE: /tmp/gcloudsvcaccount.json
          command: daemon
          restart: always
      ```

      Example `docker-compose.yaml` for Docker Swarm:

      ```yaml
      version: "3.8"

      services:
        acmesh:
          image: jmcombs/acme.sh-gcloud
          volumes:
            - acmedata:/acme.sh
            - gclouddata:/root/.config/gcloud
            - gcloudsvcaccount:/tmp/
          secrets:
            - my_secret
          networks:
            - my_network
          environment:
            GCP_SERVICE_ACCOUNT_FILE: /tmp/gcloudsvcaccount.json
          command: daemon
          deploy:
            mode: replicated
            replicas: 1

      secrets:
        my_secret:
          external: true

      networks:
        my_network:
          external: true

      volumes:
        acmedata: ...
        gclouddata: ...
        gcloudsvcaccount: ...
      ```

4. Start Docker Stack or Container:

   For Docker Desktop: **`docker compose up -d acmesh`**

   For Docker Stack: **`docker stack deploy -c docker-compose.yaml acmesh`**

5. Import Service Account (Key) into Google Cloud SDK

   ```
   docker exec -it acmesh-gcloud /bin/sh -c 'gcloud auth activate-service-account my_user@my_project.iam.gserviceaccount.com --key-file=$GCP_SERVICE_ACCOUNT_FILE'
   ```

   If successful, the following will be returned:

   ```
   Activated service account credentials for: [my_user@my_project.iam.gserviceaccount.com]
   ```

6. You can now issue certificates using **`acme.sh`** with **`dns_gcloud`**

   ```sh
   docker exec -it acmesh-gcloud /bin/sh -c 'acme.sh --issue --dns dns_gcloud -d www.example.com'
   ```

   **NOTE:** The Active Configuration for the Google Cloud SDK will be **`default`**. Changing to, and using a different Active Configuration, is out of scope for this documentation and not necessary. Advanced users can change this, if preferred.

7. (Optional) For those who Map Service Account (Key) File to Container, it is unnecessary to keep the Service Account (Key) File mapped to the Container. It is recommended to remove the **`volume`** and **`environment`** options from your **`docker-compose.yaml`** file. Example:

   ```yaml
   version: "3.8"

   services:
   acmesh:
     container_name: acmesh-gcloud
     image: jmcombs/acme.sh-gcloud
     volumes:
       - /your/local/filesystem/acmedata:/acme.sh
       - /your/local/filesystem/gclouddata:/root/.config/gcloud
     command: daemon
     restart: always
   ```

#### **Authorize with a User Account**

1. Create Container:

   Example `docker-compose.yaml` for Docker Desktop:

   ```yaml
   version: "3.8"

   services:
     acmesh:
       container_name: acmesh-gcloud
       image: jmcombs/acme.sh-gcloud
       volumes:
         - /your/local/filesystem/acmedata:/acme.sh
         - /your/local/filesystem/gclouddata:/root/.config/gcloud
       command: daemon
       restart: always
   ```

   Example `docker-compose.yaml` for Docker Swarm:

   ```yaml
   version: "3.8"

   services:
     acmesh:
       image: jmcombs/acme.sh-gcloud
       volumes:
         - acmedata:/acme.sh
         - gclouddata:/root/.config/gcloud
       networks:
         - my_network
       command: daemon
       deploy:
         mode: replicated
         replicas: 1

   networks:
     my_network:
       external: true

   volumes:
     acmedata: ...
     gclouddata: ...
   ```

2. Start Docker Stack or Container:

   For Docker Desktop: **`docker compose up -d acmesh`**

   For Docker Stack: **`docker stack deploy -c docker-compose.yaml acmesh`**

3. Run Google Cloud SDK Init Wizard

   ```
   docker exec -it acmesh-gcloud /bin/sh -c 'gcloud init'
   ```

4. You can now issue certificates using **`acme.sh`** with **`dns_gcloud`**

   ```sh
   docker exec -it acmesh-gcloud /bin/sh -c 'acme.sh --issue --dns dns_gcloud -d www.example.com'
   ```

   **NOTE:** The Active Configuration for the Google Cloud SDK will be **`default`**. Changing to, and using a different Active Configuration, is out of scope for this documentation and not necessary. Advanced users can change this, if preferred.

#### **Backlog**

1. Automating Docker Image builds when releases are pushed to either `acme.sh` or Google Cloud SDK repos
