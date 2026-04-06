FROM node:20

# Instalar git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Configurar directorio de trabajo
WORKDIR /workspace

# Instalar dependencias solo si existe package.json
RUN if [ -f package.json ]; then npm install; else echo "No package.json found. Skipping npm install."; fi

# Exponer puerto 3000
EXPOSE 3000

# Comando por defecto
CMD ["npm", "run", "dev"]
