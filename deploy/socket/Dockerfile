FROM node:20-alpine

WORKDIR /app

COPY socketio-server/package.json ./
RUN npm install --omit=dev

COPY socketio-server/server.js socketio-server/db.js ./

# Allow the self-hosted origin alongside the original Netlify one
ARG PUBLIC_ORIGIN=https://tokerrgjik.shabanejupi.tech
RUN sed -i "s|'https://tokerrgjik.netlify.app'|'https://tokerrgjik.netlify.app', '${PUBLIC_ORIGIN}'|g" server.js

EXPOSE 3001
CMD ["node", "server.js"]
