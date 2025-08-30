# prod image build stage
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY . .

# finish prod image
FROM node:20-alpine
ENV NODE_ENV=production PORT=8080
WORKDIR /home/node/app
USER node

# copy only the necessary files from deps stage
COPY --chown=node:node --from=deps /app/node_modules ./node_modules
COPY --chown=node:node --from=deps /app ./

EXPOSE 8080

# Healthcheck for k8s readiness/liveness probes
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get(`http://localhost:${process.env.PORT||8080}/`, r => process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"


CMD ["node","./bin/www"]
