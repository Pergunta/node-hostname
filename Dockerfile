# prod image build stage dependencies only
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force


# finish prod image
FROM node:20-alpine
ENV NODE_ENV=production PORT=8080
WORKDIR /home/node/app

COPY --chown=node:node --from=deps /app/node_modules ./node_modules
COPY --chown=node:node . .


USER node
EXPOSE 8080
CMD ["node","./bin/www"]
