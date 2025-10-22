FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENV REDIS_HOST=redis
ENV REDIS_PORT=6379

CMD ["node", "index.js"]
