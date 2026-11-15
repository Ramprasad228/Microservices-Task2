FROM node:20-alpine

ENV NODE_ENV=production
WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY --chown=node:node app.js ./app.js

USER node
EXPOSE 3001
CMD ["node", "app.js"]