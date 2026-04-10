FROM node:20

# Instalar git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Configurar directorio de trabajo
WORKDIR /workspace

COPY package*.json ./

# Instalar dependencias (preferir npm ci si hay lockfile)
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY . .

# Exponer puerto 3000
EXPOSE 3000

# Comando por defecto
CMD ["npm", "run", "dev"]
