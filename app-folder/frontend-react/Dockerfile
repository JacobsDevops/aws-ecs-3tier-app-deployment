FROM node:14

# Create app directory
WORKDIR /app/app


COPY ./client/package*.json ./

RUN yarn install

# copy all files into the image
COPY ./client/ .

EXPOSE 3000

CMD ["yarn", "run", "start"]