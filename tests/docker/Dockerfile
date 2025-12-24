FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run compile

COPY docker/entrypoint.sh .

RUN chmod +x entrypoint.sh

EXPOSE 8545

ENTRYPOINT ["./entrypoint.sh"]
