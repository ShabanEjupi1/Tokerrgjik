FROM node:20-alpine

WORKDIR /app

COPY netlify/functions/package.json ./
RUN npm install --omit=dev && npm install express@^4

COPY netlify/functions/ ./functions/
COPY deploy/api/server.mjs ./

EXPOSE 3000
CMD ["node", "server.mjs"]
